#!/usr/bin/env python3
"""Minimize buttons of X11 apps (Phoenix, 2026-10-17).

Hyprland ignores the "iconify" request an X11 program sends when its own minimize button is pressed (Wine/Proton
programs such as RSI Launcher, Steam-style custom title bars, old toolkits), so the button did nothing. This watcher
listens for those requests (WM_CHANGE_STATE → iconic; root SubstructureNotify) and minimizes the window with Phoenix's own
minimize (custom/execs.lua hb_minimize: the same as the title bar's minimize button; the dock brings it back).
The app is told its state like a normal window manager does (WM_STATE iconic, and normal again when the window comes
back): without that, Wine keeps thinking the window is still minimized and ignores the next minimize click.
Started with the Hyprland session by custom/scripts/autostart.sh; does nothing without python-xlib or when
"Minimize to dock" is switched off (Settings › Extras).
"""
import json
import os
import subprocess
import sys
import time

try:
    from Xlib import X, display
except ImportError:
    sys.exit(0)

FEATURES = os.path.join(os.path.expanduser("~"), ".config", "hypr", "custom", "features.lua")


def minimize_on():
    try:
        with open(FEATURES) as f:
            return "minimizeToDock = false" not in f.read().replace("  ", " ")
    except OSError:
        return True


def hypr_clients():
    try:
        return json.loads(subprocess.run(["hyprctl", "clients", "-j"], capture_output=True, text=True, timeout=5).stdout or "[]")
    except (ValueError, subprocess.SubprocessError, OSError):
        return []


def main():
    d = None
    for _ in range(120):   # Xwayland may start a moment after the session
        try:
            d = display.Display()
            break
        except Exception:
            time.sleep(1)
    if d is None:
        return 0
    root = d.screen().root
    root.change_attributes(event_mask=X.SubstructureNotifyMask)
    d.sync()
    change_state = d.intern_atom("WM_CHANGE_STATE")
    wm_pid = d.intern_atom("_NET_WM_PID")
    wm_state = d.intern_atom("WM_STATE")
    minimized = {}   # X window → {"addr", "seen" (it was in the minimized workspace), "t"}, until it comes back

    def set_state(win, state):
        try:
            win.change_property(wm_state, wm_state, 32, [state, 0])
            d.sync()
        except Exception as err:
            if os.environ.get("XMIN_DEBUG"):
                print("set_state failed:", err, flush=True)

    while True:
        if not d.pending_events():
            time.sleep(0.1)
            continue
        e = d.next_event()
        if e.type != X.ClientMessage or e.client_type != change_state:
            continue
        data = list(e.data[1])
        if os.environ.get("XMIN_DEBUG"):
            print(time.strftime("%T"), "WM_CHANGE_STATE", hex(e.window.id), data, flush=True)
        if not data or data[0] != 3:   # 3 = IconicState (a minimize request); 1 = normal
            continue
        if not minimize_on():
            continue
        win = e.window
        try:
            cls = win.get_wm_class() or ("", "")
            prop = win.get_full_property(wm_pid, 0)
            pid = int(prop.value[0]) if prop else 0
        except Exception:
            continue
        # the Hyprland window of that X11 window: same process, same class
        best = None
        for c in hypr_clients():
            if not c.get("xwayland") or c.get("pid") != pid:
                continue
            if c.get("class") in cls or c.get("initialClass") in cls:
                best = c
                if c.get("class") not in ("explorer.exe",):
                    break
        if best:
            subprocess.run(["hyprctl", "dispatch", f"hb_minimize('{best['address']}')"], capture_output=True)
            # Phoenix hides the window itself; tell the app it was iconified and restored right away, so it doesn't
            # keep thinking it is minimized (it would then treat its next minimize click as a restore)
            time.sleep(0.5)
            set_state(win, 3)
            time.sleep(0.3)
            set_state(win, 1)
            minimized[win] = {"addr": best["address"], "seen": False, "t": time.time()}
            if os.environ.get("XMIN_DEBUG"):
                print(time.strftime("%T"), "minimized", hex(win.id), best["address"], flush=True)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        pass
