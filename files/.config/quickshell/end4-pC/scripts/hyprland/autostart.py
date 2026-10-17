#!/usr/bin/env python3
"""Start the apps in Settings › Apps › Startup (config hyprland.autostartApps) — Phoenix, redone 2026-10-16.

Run once per sign-in by ~/.config/hypr/custom/scripts/autostart.sh (after the first unlock with lock-screen sign-in,
like everything else of yours), and by "Run all now" in Settings (--force: runs even when the list is switched off).
Each app opens straight on its workspace ([workspace N silent] rule): the screen no longer flips through the
workspaces while they start. Apps switched off in the Task Manager / Settings ("off": true) are skipped.
(The old version kept a lock file in /tmp, which outlives a sign-out: signing out and in again skipped your apps.)
"""
import json
import os
import subprocess
import sys
import time

CONFIG_FILE = os.path.join(os.environ.get("XDG_CONFIG_HOME") or os.path.join(os.environ["HOME"], ".config"),
                           "illogical-impulse", "config.json")
force = "--force" in sys.argv


def lua_string(text):
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def main():
    try:
        with open(CONFIG_FILE) as handle:
            autostart = json.load(handle).get("hyprland", {}).get("autostartApps", {})
    except (OSError, ValueError):
        return 0
    if not autostart.get("enable", False) and not force:
        return 0
    for app in autostart.get("apps", []):
        command = str(app.get("cmd", "")).strip()
        if not command or app.get("off"):
            continue
        workspace = int(app.get("workspace", 1) or 1)
        delay = float(app.get("delay", 0) or 0)
        expr = f"hl.dsp.exec_cmd({lua_string(os.path.expanduser(command))}, {{ workspace = \"{workspace} silent\" }})"
        subprocess.run(["hyprctl", "dispatch", expr], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if delay > 0:
            time.sleep(delay)
    return 0


if __name__ == "__main__":
    sys.exit(main())
