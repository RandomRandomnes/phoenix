#!/usr/bin/env python3
"""Process sampler for the Phoenix Task Manager (task-manager.qml), 2026-10-15, ours; not upstream.

Prints one JSON line per interval (default 1.5 s):
  {"totals": {cpu, mem, memUsed, memTotal, gpu, diskRead, diskWrite, diskBusy, procs, threads},
   "drives": [{dev, model, kind ("NVMe SSD"|"SSD"|"HDD", " (USB)" when on USB), size, read, write, busy,
               mounts: [{path, label, fs, used, total}]}]   every disk with a mounted drive on it (2026-10-17)
   "groups": [{kind: "app"|"background"|"system", key, name, cls, title, pid, user, own,
               cpu, mem, gpu, disk, count, pids}]}
cpu = share of the whole machine in % (like Windows), mem = resident bytes (RSS), gpu = % of one GPU engine
(AMD/Intel drm fdinfo, own processes only), disk = bytes/s read+written (own processes only).
Apps = processes that own a window (hyprctl clients) with everything started under them; background = your other
processes, each with its children; system = other users' processes (root, services), per process.
"""
import json
import os
import pwd
import subprocess
import sys
import time

try:
    INTERVAL = max(0.5, float(sys.argv[1])) if len(sys.argv) > 1 else 1.5
except ValueError:
    INTERVAL = 1.5
MY_UID = os.getuid()
CLK = os.sysconf("SC_CLK_TCK")
PAGE = os.sysconf("SC_PAGE_SIZE")
NCPU = os.cpu_count() or 1


def read(path):
    try:
        with open(path) as f:
            return f.read()
    except OSError:
        return None


def users():
    cache = {}

    def name(uid):
        if uid not in cache:
            try:
                cache[uid] = pwd.getpwuid(uid).pw_name
            except KeyError:
                cache[uid] = str(uid)
        return cache[uid]
    return name


user_name = users()


def total_jiffies():
    line = (read("/proc/stat") or "cpu 0").splitlines()[0].split()[1:]
    vals = [int(v) for v in line]
    idle = vals[3] + (vals[4] if len(vals) > 4 else 0)
    return sum(vals), idle


def meminfo():
    m = {}
    for line in (read("/proc/meminfo") or "").splitlines():
        k, _, v = line.partition(":")
        m[k] = int(v.split()[0]) * 1024 if v.split() else 0
    total = m.get("MemTotal", 1)
    used = total - m.get("MemAvailable", total)
    return total, used


def gpu_busy():
    best = None
    for card in sorted(os.listdir("/sys/class/drm")) if os.path.isdir("/sys/class/drm") else []:
        v = read(f"/sys/class/drm/{card}/device/gpu_busy_percent")
        if v and v.strip().isdigit():
            best = max(best or 0, int(v))
    return best


def disk_sectors():
    """read and written sectors and busy ms of whole disks (no partitions, no loop/zram)"""
    r = w = busy = 0
    for line in (read("/proc/diskstats") or "").splitlines():
        p = line.split()
        if len(p) < 14:
            continue
        dev = p[2]
        if dev.startswith(("loop", "ram", "zram", "dm-", "sr")):
            continue
        if os.path.exists(f"/sys/block/{dev}"):   # a whole disk, not a partition
            r += int(p[5])
            w += int(p[9])
            busy = max(busy, int(p[12]))
    return r * 512, w * 512, busy


REAL_FS = {"ext4", "ext3", "ext2", "btrfs", "xfs", "f2fs", "vfat", "exfat", "ntfs", "ntfs3", "fuseblk", "zfs", "bcachefs"}


def unescape(path):
    return path.replace("\\040", " ").replace("\\011", "\t").replace("\\134", "\\")


def whole_disks(dev):
    """whole disk(s) a block device lives on: nvme0n1p2 -> nvme0n1; dm-1 (LVM, LUKS) -> the disks under it"""
    if os.path.exists(f"/sys/block/{dev}") and not dev.startswith("dm-"):
        return {dev}
    if dev.startswith("dm-"):
        out = set()
        for s in os.listdir(f"/sys/block/{dev}/slaves") if os.path.isdir(f"/sys/block/{dev}/slaves") else []:
            out |= whole_disks(s)
        return out
    link = os.path.realpath(f"/sys/class/block/{dev}")
    parent = os.path.basename(os.path.dirname(link))
    return {parent} if os.path.exists(f"/sys/block/{parent}") else set()


def udev_model(dev):
    try:
        majmin = read(f"/sys/block/{dev}/dev").strip()
        for line in (read(f"/run/udev/data/b{majmin}") or "").splitlines():
            if line.startswith("E:ID_MODEL="):
                return line.split("=", 1)[1].replace("_", " ").strip()
    except AttributeError:
        pass
    return (read(f"/sys/block/{dev}/device/model") or dev).strip()


def mount_label(path):
    home = os.path.expanduser("~")
    if path == "/":
        return "System"
    if path == home or path == "/home":
        return "Home"
    if path == "/boot" or path == "/efi" or path == "/boot/efi":
        return "Boot"
    return os.path.basename(path) or path


def drives(stats, prev, dt):
    """every disk with a mounted drive on it: model, type, size, read/write speed, busy, and space per drive"""
    found = {}
    seen = set()
    for line in (read("/proc/mounts") or "").splitlines():
        p = line.split()
        if len(p) < 3 or not p[0].startswith("/dev/") or p[2] not in REAL_FS:
            continue
        path = unescape(p[1])
        try:
            st = os.statvfs(path)
            dev_id = os.stat(path).st_dev
        except OSError:
            continue
        if dev_id in seen:   # the same drive mounted twice (bind mounts)
            continue
        seen.add(dev_id)
        blk = os.path.basename(os.path.realpath(p[0]))
        m = {"path": path, "label": mount_label(path), "fs": p[2],
             "used": (st.f_blocks - st.f_bfree) * st.f_frsize, "total": st.f_blocks * st.f_frsize}
        for d in sorted(whole_disks(blk)):
            found.setdefault(d, []).append(m)
    out = []
    for d, mounts in found.items():
        f = stats.get(d)
        r = w = busy = 0
        if f and prev.get(d) and dt:
            r = round((f[0] - prev[d][0]) / dt)
            w = round((f[1] - prev[d][1]) / dt)
            busy = round(min(100.0, (f[2] - prev[d][2]) / (dt * 10)), 1)
        rota = (read(f"/sys/block/{d}/queue/rotational") or "0").strip() == "1"
        kind = "NVMe SSD" if d.startswith("nvme") else ("HDD" if rota else "SSD")
        if "/usb" in os.path.realpath(f"/sys/block/{d}"):
            kind += " (USB)"
        size = int((read(f"/sys/block/{d}/size") or "0").strip() or 0) * 512
        order = 0 if any(m["path"] == "/" for m in mounts) else 1
        out.append({"dev": d, "model": udev_model(d), "kind": kind, "size": size, "read": r, "write": w,
                    "busy": busy, "mounts": sorted(mounts, key=lambda m: (m["path"] != "/", m["path"])), "_o": order})
    out.sort(key=lambda x: (x.pop("_o"), x["dev"]))
    return out


def disk_stats():
    """per whole disk: read bytes, written bytes, busy ms"""
    out = {}
    for line in (read("/proc/diskstats") or "").splitlines():
        p = line.split()
        if len(p) >= 14 and os.path.exists(f"/sys/block/{p[2]}"):
            out[p[2]] = (int(p[5]) * 512, int(p[9]) * 512, int(p[12]))
    return out


def windows():
    try:
        out = subprocess.run(["hyprctl", "clients", "-j"], capture_output=True, text=True, timeout=2).stdout
        return {c["pid"]: c for c in json.loads(out or "[]") if c.get("pid", -1) > 0}
    except (OSError, ValueError, subprocess.SubprocessError):
        return {}


def gpu_ns(pid):
    """drm engine busy time of a process in ns (sum over its drm clients, de-duplicated by client id)"""
    seen, total = set(), 0
    try:
        fds = os.listdir(f"/proc/{pid}/fdinfo")
    except OSError:
        return None
    for fd in fds:
        t = read(f"/proc/{pid}/fdinfo/{fd}")
        if not t or "drm-client-id" not in t:
            continue
        cid, ns = None, 0
        for line in t.splitlines():
            if line.startswith("drm-client-id:"):
                cid = line.split()[1]
            elif line.startswith("drm-engine-") and line.split()[1].isdigit():
                ns += int(line.split()[1])
        if cid in seen:
            continue
        seen.add(cid)
        total += ns
    return total


prev = {"t": None, "jiff": None, "procs": {}, "gpu": {}, "io": {}, "disk": None}
drm_pids, drm_scan = set(), 0


def sample():
    global drm_pids, drm_scan
    now = time.monotonic()
    jiff, idle = total_jiffies()
    dt = (now - prev["t"]) if prev["t"] else None
    djiff = (jiff - prev["jiff"][0]) if prev["jiff"] else None
    procs, threads = {}, 0
    for d in os.listdir("/proc"):
        if not d.isdigit():
            continue
        pid = int(d)
        stat = read(f"/proc/{pid}/stat")
        if not stat:
            continue
        try:
            name = stat[stat.index("(") + 1:stat.rindex(")")]
            rest = stat[stat.rindex(")") + 2:].split()
            ppid, utime, stime, nthreads, rss = int(rest[1]), int(rest[11]), int(rest[12]), int(rest[17]), int(rest[21])
            uid = os.stat(f"/proc/{pid}").st_uid
        except (ValueError, IndexError, OSError):
            continue
        if ppid == 2 or pid == 2:   # kernel threads
            continue
        threads += nthreads
        cpu_t = utime + stime
        p = {"pid": pid, "ppid": ppid, "uid": uid, "name": name, "rss": rss * PAGE, "cpu_t": cpu_t, "cpu": 0.0,
             "gpu": 0.0, "disk": 0.0}
        old = prev["procs"].get(pid)
        if old and djiff and old["name"] == name:
            p["cpu"] = max(0.0, (cpu_t - old["cpu_t"]) * 100.0 / djiff)
        if uid == MY_UID:
            io = read(f"/proc/{pid}/io")
            if io:
                b = 0
                for line in io.splitlines():
                    if line.startswith(("read_bytes:", "write_bytes:")):
                        b += int(line.split()[1])
                o = prev["io"].get(pid)
                if o is not None and dt:
                    p["disk"] = max(0.0, (b - o) / dt)
                prev["io"][pid] = b
        procs[pid] = p
    # GPU: find processes with drm clients every 10 samples, read their engine time every sample
    drm_scan -= 1
    if drm_scan <= 0:
        drm_scan = 10
        drm_pids = set()
        for pid, p in procs.items():
            if p["uid"] != MY_UID:
                continue
            try:
                for fd in os.listdir(f"/proc/{pid}/fd"):
                    if os.readlink(f"/proc/{pid}/fd/{fd}").startswith("/dev/dri/"):
                        drm_pids.add(pid)
                        break
            except OSError:
                pass
    for pid in drm_pids:
        if pid not in procs:
            continue
        ns = gpu_ns(pid)
        if ns is None:
            continue
        o = prev["gpu"].get(pid)
        if o is not None and dt:
            procs[pid]["gpu"] = min(100.0, max(0.0, (ns - o) / (dt * 1e9) * 100.0))
        prev["gpu"][pid] = ns
    for k in list(prev["io"]):
        if k not in procs:
            del prev["io"][k]
    for k in list(prev["gpu"]):
        if k not in procs:
            del prev["gpu"][k]

    # grouping
    children = {}
    for pid, p in procs.items():
        children.setdefault(p["ppid"], []).append(pid)

    def tree(pid, taken):
        out, stack = [], [pid]
        while stack:
            q = stack.pop()
            if q in taken or q not in procs:
                continue
            taken.add(q)
            out.append(q)
            stack.extend(children.get(q, []))
        return out

    wins = windows()
    taken, groups = set(), []
    # apps: window owners (several windows of one process = one app)
    for pid, w in sorted(wins.items(), key=lambda kv: kv[1].get("class", "").lower()):
        if pid not in procs or pid in taken:
            continue
        # the desktop shell's own windows (Settings, the Task Manager itself): the shell isn't an app you opened, it
        # stays with the background processes as "qs" (2026-10-16: the Task Manager became a window of the shell)
        if procs[pid]["name"] == "qs" and w.get("class") == "org.quickshell":
            continue
        pids = tree(pid, taken)
        groups.append({"kind": "app", "key": f"app:{pid}", "name": w.get("initialTitle") or w.get("class") or procs[pid]["name"],
                       "cls": w.get("class", ""), "title": w.get("title", ""), "pid": pid, "pids": pids})
    # your other processes, one row per program name (an app's helper processes, e.g. 8× electron, stay together;
    # the desktop session's own programs show separately instead of all under start-hyprland)
    byname = {}
    for pid in sorted(pid for pid, p in procs.items() if p["uid"] == MY_UID and pid not in taken):
        byname.setdefault(procs[pid]["name"], []).append(pid)
    for name, pids in sorted(byname.items()):
        taken.update(pids)
        groups.append({"kind": "background", "key": f"bg:{name}", "name": name, "cls": "", "title": "",
                       "pid": pids[0], "pids": pids})
    for pid in sorted(procs):
        if pid in taken:
            continue
        taken.add(pid)
        groups.append({"kind": "system", "key": f"sys:{pid}", "name": procs[pid]["name"], "cls": "", "title": "",
                       "pid": pid, "pids": [pid]})
    for g in groups:
        ps = [procs[q] for q in g["pids"]]
        g["cpu"] = round(sum(x["cpu"] for x in ps), 2)
        g["mem"] = sum(x["rss"] for x in ps)
        g["gpu"] = round(min(100.0, sum(x["gpu"] for x in ps)), 1)
        g["disk"] = round(sum(x["disk"] for x in ps))
        g["count"] = len(ps)
        g["user"] = user_name(procs[g["pid"]]["uid"])
        g["own"] = procs[g["pid"]]["uid"] == MY_UID
        cmd = (read(f"/proc/{g['pid']}/cmdline") or "").replace("\0", " ").strip()
        g["cmd"] = cmd[:300]

    total, used = meminfo()
    dr, dw, busy = disk_sectors()
    dstats = disk_stats()
    totals = {"cpu": round((1 - (idle - prev["jiff"][1]) / djiff) * 100, 1) if djiff else 0.0,
              "memUsed": used, "memTotal": total, "mem": round(used * 100 / total, 1),
              "gpu": gpu_busy(), "diskRead": 0, "diskWrite": 0, "diskBusy": 0.0,
              "procs": len(procs), "threads": threads, "cpus": NCPU}
    if prev["disk"] and dt:
        totals["diskRead"] = round((dr - prev["disk"][0]) / dt)
        totals["diskWrite"] = round((dw - prev["disk"][1]) / dt)
        totals["diskBusy"] = round(min(100.0, (busy - prev["disk"][2]) / (dt * 10)), 1)
    drv = drives(dstats, prev.get("dstats") or {}, dt if prev["disk"] else 0)
    prev.update({"t": now, "jiff": (jiff, idle), "procs": procs, "disk": (dr, dw, busy), "dstats": dstats})
    return {"totals": totals, "groups": groups, "drives": drv}


if __name__ == "__main__":
    sample()
    time.sleep(0.3)
    while True:
        try:
            print(json.dumps(sample(), separators=(",", ":")), flush=True)
        except BrokenPipeError:
            break
        time.sleep(INTERVAL)
