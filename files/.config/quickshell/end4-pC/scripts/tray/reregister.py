#!/usr/bin/env python3
"""Bring bridged X11/Wine tray icons back after the shell restarts (Phoenix, 2026-10-17).

The shell owns the tray list (StatusNotifierWatcher). When it restarts, xembedsniproxy (the bridge for X11/Wine tray
icons) still holds the icons but doesn't announce them again, so they vanish from the bar; restarting the bridge
doesn't help either (Wine drops an icon whose tray goes away and never recreates it). The shell runs this once it has
started: every icon the bridge still offers is announced to the new tray list.
"""
import subprocess
import sys


def call(*args):
    return subprocess.run(["busctl", "--user", "--json=short", *args], capture_output=True, text=True, timeout=5)


def main():
    import json
    try:
        bridge = subprocess.run(["pgrep", "-x", "xembedsniproxy"], capture_output=True, text=True).stdout.split()
    except OSError:
        return 0
    if not bridge:
        return 0
    try:
        names = json.loads(call("call", "org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus",
                                "ListNames").stdout)["data"][0]
        known = json.loads(call("get-property", "org.kde.StatusNotifierWatcher", "/StatusNotifierWatcher",
                                "org.kde.StatusNotifierWatcher", "RegisteredStatusNotifierItems").stdout)["data"]
    except (ValueError, KeyError, IndexError, subprocess.SubprocessError):
        return 0
    known = {k.split("/")[0] for k in known}
    for n in names:
        if not n.startswith(":") or n in known:
            continue
        try:
            pid = json.loads(call("call", "org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus",
                                  "GetConnectionUnixProcessID", "s", n).stdout)["data"][0]
        except (ValueError, KeyError, IndexError, subprocess.SubprocessError):
            continue
        if str(pid) not in bridge:
            continue
        # the bridge's own control connection has no tray item: only names that answer as one are announced
        if call("get-property", n, "/StatusNotifierItem", "org.kde.StatusNotifierItem", "Id").returncode != 0:
            continue
        call("call", "org.kde.StatusNotifierWatcher", "/StatusNotifierWatcher", "org.kde.StatusNotifierWatcher",
             "RegisterStatusNotifierItem", "s", n)
    return 0


if __name__ == "__main__":
    sys.exit(main())
