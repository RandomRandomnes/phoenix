#!/usr/bin/env python3
"""Name for a tray icon that came through the XEmbed bridge (xembedsniproxy), Phoenix 2026-10-17.

  xembed-name.py <x11 window id, decimal>     prints a name, e.g. "RSI Launcher"

Such icons (Wine/Proton programs) have no title or tooltip, only the number of their X11 window, so the tray showed
that number. The name: the window's process → its Wine prefix → the title of the program's main window (found through
Hyprland) → else the name of the Windows program running in that prefix (a program that lives in the tray, like
RSI Launcher, has no window) → else the window's class (explorer.exe → "explorer") → else the process name.
"""
import json
import os
import re
import subprocess
import sys


def sh(cmd):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=5).stdout
    except (OSError, subprocess.SubprocessError):
        return ""


def environ(pid, key):
    try:
        with open(f"/proc/{pid}/environ", "rb") as f:
            for item in f.read().split(b"\0"):
                if item.startswith(key.encode() + b"="):
                    return item.split(b"=", 1)[1].decode(errors="replace")
    except OSError:
        pass
    return ""


def main():
    try:
        wid = int(sys.argv[1])
    except (IndexError, ValueError):
        return 1
    out = sh(["xprop", "-id", hex(wid), "_NET_WM_PID", "WM_CLASS", "_NET_WM_NAME"])
    m = re.search(r"_NET_WM_PID\(CARDINAL\) = (\d+)", out)
    pid = int(m.group(1)) if m else 0
    name = (re.search(r'_NET_WM_NAME\(UTF8_STRING\) = "(.+)"', out) or [None, ""])[1]
    if name:
        print(name)
        return 0
    prefix = environ(pid, "WINEPREFIX") if pid else ""
    if prefix:
        try:
            clients = json.loads(sh(["hyprctl", "clients", "-j"]) or "[]")
        except ValueError:
            clients = []
        for c in clients:
            if c.get("class") in ("explorer.exe", "") or c.get("title") == "Wine System Tray":
                continue
            if environ(c.get("pid", 0), "WINEPREFIX") == prefix and c.get("title"):
                print(c["title"])
                return 0
    if prefix:   # no window of its own (the program lives in the tray): the Windows program running in this prefix
        found = []
        for d in os.listdir("/proc"):
            if not d.isdigit() or environ(int(d), "WINEPREFIX") != prefix:
                continue
            try:
                with open(f"/proc/{d}/cmdline", "rb") as f:
                    cmd = f.read().split(b"\0")[0].decode(errors="replace")
            except OSError:
                continue
            if re.match(r"^[A-Za-z]:\\", cmd) and not re.match(r"^[A-Za-z]:\\windows\\", cmd, re.I):
                found.append((int(d), cmd))
        if found:
            print(re.sub(r"\.exe$", "", found[0 if len(found) == 1 else 0][1].rsplit("\\", 1)[-1], flags=re.I))
            return 0
    cls = re.search(r'WM_CLASS\(STRING\) = "[^"]*", "([^"]*)"', out)
    if cls and cls.group(1) and cls.group(1) != "explorer.exe":
        print(re.sub(r"\.exe$", "", cls.group(1)))
        return 0
    try:
        with open(f"/proc/{pid}/comm") as f:
            print(f.read().strip())
        return 0
    except OSError:
        return 1


if __name__ == "__main__":
    sys.exit(main())
