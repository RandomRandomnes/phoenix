#!/usr/bin/env python3
"""Wallpaper Engine state for the shell (Phoenix, 2026-10-16; replaces a `sh` + `pgrep` started twice a second).

Prints one JSON line whenever something changes: {"procs": [[argv...], ...], "muted": bool}
  procs  the running renderers (argv[0] ends in linux-wallpaperengine, -inshell or -web), full argument lists
  muted  $XDG_STATE_HOME/wallpaper-engine-muted exists
One long-lived process: it reads /proc itself (no new processes per check) and stays quiet while nothing changes.
"""
import json
import os
import re
import sys
import time

INTERVAL = float(sys.argv[1]) if len(sys.argv) > 1 else 0.5
NAME = re.compile(r"linux-wallpaperengine(-inshell|-web)?$")
MUTED = os.path.join(os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state"), "wallpaper-engine-muted")
UID = os.getuid()


def renderers():
    out = []
    for pid in os.listdir("/proc"):
        if not pid.isdigit():
            continue
        try:
            if os.stat(f"/proc/{pid}").st_uid != UID:
                continue
            with open(f"/proc/{pid}/cmdline", "rb") as f:
                raw = f.read()
        except OSError:
            continue
        if b"wallpaperengine" not in raw:
            continue
        args = [a.decode(errors="replace").replace("\n", " ") for a in raw.split(b"\0")]
        if args and args[-1] == "":
            args.pop()
        if args and NAME.search(args[0]):
            out.append(args)
    out.sort()
    return out


def main():
    last = None
    while True:
        try:
            cur = json.dumps({"procs": renderers(), "muted": os.path.exists(MUTED)})
        except Exception as e:   # keep going: a vanished process mid-read, etc.
            cur = last or json.dumps({"procs": [], "muted": False, "error": str(e)})
        if cur != last:
            print(cur, flush=True)
            last = cur
        time.sleep(INTERVAL)


if __name__ == "__main__":
    main()
