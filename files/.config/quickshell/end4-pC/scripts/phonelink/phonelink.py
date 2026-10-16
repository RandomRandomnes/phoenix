#!/usr/bin/env python3
"""Phone Link helper (Phoenix P6, 2026-10-15, ours; not upstream). Talks to KDE Connect's daemon (kdeconnectd) over D-Bus.

  phonelink.py watch [seconds]        one JSON line per change: {"ok", "installed", "running", "devices": [...]}
  phonelink.py ring|clipboard|browse|messages <device>
  phonelink.py share <device> <file>...     send files to the phone
  phonelink.py reply <device> <replyId> <text>
  phonelink.py dismiss <device> <notificationId>
  phonelink.py media <device> <PlayPause|Next|Previous|Play|Pause>
  phonelink.py photos <device>        newest photos (mounts the phone's storage): {"photos": [paths]}
  phonelink.py pair|unpair|accept|reject <device>
  phonelink.py refresh                look for phones on the network again
  phonelink.py plugin <device> <plugin> on|off    e.g. kdeconnect_clipboard (written to KDE Connect's config)

A device in "devices": id, name, type, paired, reachable, pairRequested (by the phone), battery, charging,
network ("5G"), signal (0-4), notifications [{id, app, title, text, reply, dismissable}], media {player, title,
artist, playing, art} or null, plugins {name: enabled}.
"""
import configparser
import json
import os
import shutil
import sys
import time

BUS = "org.kde.kdeconnect"
ROOT = "/modules/kdeconnect"
PLUGINS = ["kdeconnect_notifications", "kdeconnect_sms", "kdeconnect_telephony", "kdeconnect_pausemusic",
           "kdeconnect_clipboard", "kdeconnect_mousepad", "kdeconnect_remotekeyboard", "kdeconnect_mprisremote",
           "kdeconnect_mpriscontrol", "kdeconnect_sftp", "kdeconnect_share", "kdeconnect_findmyphone"]

try:
    import dbus
except ImportError:   # python-dbus missing: report it, the card shows "not set up"
    dbus = None


def bus():
    return dbus.SessionBus()


def obj(path):
    return bus().get_object(BUS, path)


def props(path, iface):
    try:
        return {str(k): v for k, v in obj(path).GetAll(iface, dbus_interface="org.freedesktop.DBus.Properties").items()}
    except Exception:
        return {}


def call(path, iface, method, *args, **kw):
    return getattr(dbus.Interface(obj(path), iface), method)(*args, **kw)


def py(v):
    """dbus types → plain JSON-able values"""
    if isinstance(v, (dbus.Boolean,)):
        return bool(v)
    if isinstance(v, (dbus.Int32, dbus.Int64, dbus.UInt32, dbus.UInt64, dbus.Int16, dbus.UInt16, dbus.Byte)):
        return int(v)
    if isinstance(v, dbus.Double):
        return float(v)
    if isinstance(v, (dbus.String, dbus.ObjectPath)):
        return str(v)
    if isinstance(v, (dbus.Array, list)):
        return [py(x) for x in v]
    if isinstance(v, (dbus.Dictionary, dict)):
        return {str(k): py(x) for k, x in v.items()}
    return v


def config_path(dev):
    return os.path.expanduser(f"~/.config/kdeconnect/{dev}/config")


def plugin_states(dev, loaded):
    cfg = configparser.ConfigParser(strict=False)
    cfg.optionxform = str
    cfg.read(config_path(dev))
    sec = cfg["Plugins"] if cfg.has_section("Plugins") else {}
    out = {}
    for p in PLUGINS:
        v = sec.get(p + "Enabled") if sec else None
        out[p] = (v == "true") if v is not None else (p in loaded or p != "kdeconnect_clipboard")
    return out


def device(dev):
    base = f"{ROOT}/devices/{dev}"
    d = props(base, "org.kde.kdeconnect.device")
    out = {"id": dev, "name": str(d.get("name", dev)), "type": str(d.get("type", "phone")),
           "paired": bool(d.get("isPaired", False)), "reachable": bool(d.get("isReachable", False)),
           "pairRequested": False, "battery": None, "charging": False, "network": "", "signal": -1,
           "notifications": [], "media": None, "plugins": {}}
    out["pairRequested"] = bool(d.get("isPairRequestedByPeer", False))
    loaded = []
    try:
        loaded = [str(x) for x in call(base, "org.kde.kdeconnect.device", "loadedPlugins")]
    except Exception:
        pass
    out["plugins"] = plugin_states(dev, loaded)
    if not (out["paired"] and out["reachable"]):
        return out
    b = props(base + "/battery", "org.kde.kdeconnect.device.battery")
    if b.get("hasBattery"):
        out["battery"] = int(b.get("charge", -1))
        out["charging"] = bool(b.get("isCharging", False))
    c = props(base + "/connectivity_report", "org.kde.kdeconnect.device.connectivity_report")
    if c:
        net = str(c.get("cellularNetworkType", ""))
        if net and net.lower() not in ("unknown", "none"):   # "Unknown" while there's no mobile data: leave it out
            out["network"] = net
            out["signal"] = int(c.get("cellularNetworkStrength", -1))
    try:
        ids = call(base + "/notifications", "org.kde.kdeconnect.device.notifications", "activeNotifications")
    except Exception:
        ids = []
    for nid in list(ids)[-20:]:
        n = props(f"{base}/notifications/{nid}", "org.kde.kdeconnect.device.notifications.notification")
        if not n:
            continue
        out["notifications"].append({"id": str(nid), "app": str(n.get("appName", "")), "title": str(n.get("title", "")),
                                     "text": str(n.get("text", "") or n.get("ticker", "")),
                                     "reply": str(n.get("replyId", "")), "dismissable": bool(n.get("dismissable", False))})
    m = props(base + "/mprisremote", "org.kde.kdeconnect.device.mprisremote")
    if m and m.get("playerList"):
        out["media"] = {"player": str(m.get("player", "")), "title": str(m.get("title", "")), "artist": str(m.get("artist", "")),
                        "playing": bool(m.get("isPlaying", False)), "art": str(m.get("localAlbumArtUrl", ""))}
    return out


def state():
    s = {"ok": True, "installed": shutil.which("kdeconnect-cli") is not None or os.path.exists("/usr/bin/kdeconnectd"),
         "running": False, "devices": []}
    if dbus is None:
        s["ok"] = False
        return s
    try:
        # only look when it's running: a call would start it through D-Bus, even with Phone Link switched off at
        # sign-in (Task Manager › Startup, 2026-10-16); the card's buttons and Settings start it when used
        if not bus().name_has_owner(BUS):
            return s
        ids = call(ROOT, "org.kde.kdeconnect.daemon", "devices", False, False)
        s["running"] = True
    except Exception:
        return s
    for dev in ids:
        try:
            s["devices"].append(device(str(dev)))
        except Exception:
            pass
    # paired phones first, then ones asking to pair, then others on the network
    s["devices"].sort(key=lambda d: (not d["paired"], not d["pairRequested"], d["name"].lower()))
    return s


def watch(interval):
    last = None
    while True:
        try:
            cur = json.dumps(state(), separators=(",", ":"))
        except Exception as e:
            cur = json.dumps({"ok": False, "error": str(e)})
        if cur != last:
            print(cur, flush=True)
            last = cur
        time.sleep(interval)


def set_plugin(dev, plugin, on):
    p = config_path(dev)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    cfg = configparser.ConfigParser(strict=False)
    cfg.optionxform = str
    cfg.read(p)
    if not cfg.has_section("Plugins"):
        cfg.add_section("Plugins")
    cfg["Plugins"][plugin + "Enabled"] = "true" if on else "false"
    tmp = p + ".tmp"
    with open(tmp, "w") as f:
        cfg.write(f, space_around_delimiters=False)
    os.replace(tmp, p)
    call(f"{ROOT}/devices/{dev}", "org.kde.kdeconnect.device", "reloadPlugins")


def photos(dev):
    base = f"{ROOT}/devices/{dev}/sftp"
    iface = "org.kde.kdeconnect.device.sftp"

    def mount(fresh):
        if fresh:   # a mount made before the phone allowed file access stays "Permission denied": mount again
            try:
                call(base, iface, "unmount")
            except Exception:
                pass
        if not call(base, iface, "isMounted"):
            call(base, iface, "mountAndWait", timeout=20)
        return str(call(base, iface, "mountPoint"))

    def scan(mp):
        found = []
        # the folders the phone shares (newer Android: e.g. .../storage/emulated/0 "Internal storage"; the mount point
        # itself isn't readable there), else whatever is at the top of the mount
        try:
            roots = [str(k) for k in call(base, iface, "getDirectories").keys()]
        except Exception:
            roots = []
        if not roots:
            roots = [mp] + [os.path.join(mp, x) for x in sorted(os.listdir(mp)) if os.path.isdir(os.path.join(mp, x))]
        for root in roots:
            cam = os.path.join(root, "DCIM", "Camera")
            if os.path.isdir(cam):
                # Samsung names photos by date (20261015_142233.jpg): the name order is the time order, no stat over sshfs
                names = sorted(n for n in os.listdir(cam) if n.lower().endswith((".jpg", ".jpeg", ".png", ".heic", ".webp")))
                found += [os.path.join(cam, n) for n in names[-8:]]
        found.sort(key=os.path.basename)
        return found[-4:][::-1]

    for fresh in (False, True):
        try:
            mp = mount(fresh)
            return {"photos": scan(mp), "mount": mp}
        except PermissionError:
            continue
        except Exception as e:
            return {"photos": [], "error": str(e)}
    return {"photos": [], "error": "the phone doesn't allow file access (KDE Connect app › Filesystem expose)"}


def main():
    a = sys.argv[1:]
    if not a:
        print(__doc__)
        return 1
    cmd = a[0]
    if cmd == "watch":
        watch(float(a[1]) if len(a) > 1 else 2.0)
        return 0
    if dbus is None:
        print("python-dbus is missing", file=sys.stderr)
        return 1
    if cmd == "refresh":
        call(ROOT, "org.kde.kdeconnect.daemon", "forceOnNetworkChange")
        return 0
    dev = a[1] if len(a) > 1 else ""
    base = f"{ROOT}/devices/{dev}"
    if cmd == "ring":
        call(base + "/findmyphone", "org.kde.kdeconnect.device.findmyphone", "ring")
    elif cmd == "clipboard":
        call(base + "/clipboard", "org.kde.kdeconnect.device.clipboard", "sendClipboard")
    elif cmd == "browse":
        call(base + "/sftp", "org.kde.kdeconnect.device.sftp", "startBrowsing")
    elif cmd == "messages":
        call(base + "/sms", "org.kde.kdeconnect.device.sms", "launchApp")
    elif cmd == "share":
        urls = ["file://" + os.path.abspath(f) for f in a[2:]]
        if urls:
            call(base + "/share", "org.kde.kdeconnect.device.share", "shareUrls", dbus.Array(urls, signature="s"))
    elif cmd == "reply":
        call(base + "/notifications", "org.kde.kdeconnect.device.notifications", "sendReply", a[2], a[3])
    elif cmd == "dismiss":
        call(f"{base}/notifications/{a[2]}", "org.kde.kdeconnect.device.notifications.notification", "dismiss")
    elif cmd == "media":
        call(base + "/mprisremote", "org.kde.kdeconnect.device.mprisremote", "sendAction", a[2])
    elif cmd == "photos":
        print(json.dumps(photos(dev)))
    elif cmd in ("pair", "unpair", "accept", "reject"):
        call(base, "org.kde.kdeconnect.device",
             {"pair": "requestPairing", "unpair": "unpair", "accept": "acceptPairing", "reject": "cancelPairing"}[cmd])
    elif cmd == "plugin":
        set_plugin(dev, a[2], a[3] == "on")
    else:
        print(__doc__)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
