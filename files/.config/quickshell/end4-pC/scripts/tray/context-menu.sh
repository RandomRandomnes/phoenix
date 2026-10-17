#!/bin/bash
# Menu actions for bridged X11/Wine tray icons (Phoenix, 2026-10-17). These icons (via xembedsniproxy) have no menu of
# their own and Wine ignores the forwarded right-click, so the shell draws Open / Quit itself.
# usage: context-menu.sh quit <tray item id = X window id>
[ "$1" = quit ] || exit 1
pid=$(xprop -id "$2" _NET_WM_PID 2>/dev/null | awk '{print $NF}')
[[ "$pid" =~ ^[0-9]+$ ]] || exit 1
# the whole program, not just the tray window: ask politely first
pkill -TERM -P "$pid" 2>/dev/null; kill -TERM "$pid" 2>/dev/null
