#!/bin/sh
log="$HOME/.local/state/phoenix/autostart.log"; mkdir -p "$HOME/.local/state/phoenix"
echo "$(date +%T) autostart script started" > "$log"
# With lock-screen sign-in (PHOENIX_LOCK_FIRST=1, see phoenix-session) your things wait for the first unlock: the lock
# screen leaves $XDG_RUNTIME_DIR/phoenix-unlocked-once (per sign-in: the runtime folder is emptied at sign-out).
wait_unlocked() {
  [ "${PHOENIX_LOCK_FIRST:-}" = 1 ] || return 0
  while [ ! -e "${XDG_RUNTIME_DIR:-/tmp}/phoenix-unlocked-once" ]; do sleep 1; done
}
# Your own login commands (not part of Phoenix, never shipped or overwritten): custom/scripts/autostart-user.sh
# With lock-screen sign-in (PHOENIX_LOCK_FIRST=1, see phoenix-session) they wait for the first unlock: nothing of yours
# (drive mounts, apps) runs before the password. The lock screen leaves $XDG_RUNTIME_DIR/phoenix-unlocked-once.
if [ -f "$HOME/.config/hypr/custom/scripts/autostart-user.sh" ]; then
  (
    [ "${PHOENIX_LOCK_FIRST:-}" = 1 ] && echo "$(date +%T) autostart-user.sh waits for the first unlock" >> "$log"
    wait_unlocked
    echo "$(date +%T) running autostart-user.sh" >> "$log"
    sh "$HOME/.config/hypr/custom/scripts/autostart-user.sh" >> "$log" 2>&1
  ) &
fi
# In a virtual machine, idle sleep (hypridle → systemctl suspend) freezes the virtual graphics card on wake-up and the VM
# can then only be reset (QA 2026-10-08): hold off sleep for this session there. Real PCs are not affected.
if command -v systemd-detect-virt >/dev/null && systemd-detect-virt -q --vm; then
  echo "$(date +%T) virtual machine: sleep is held off for this session" >> "$log"
  systemd-inhibit --what=sleep --who=Phoenix --why="Sleep freezes the graphics of virtual machines" sleep infinity >/dev/null 2>&1 &
fi
# The login screen (phoenix login-screen install) shows this desktop's wallpaper and colors: refresh its copy
[ -x "$HOME/.local/bin/phoenix-greeter-theme" ] && "$HOME/.local/bin/phoenix-greeter-theme" >> "$log" 2>&1 &
# Custom-feature switches (Settings › Extras, written by ~/.local/bin/setup-features). Missing = on.
feature() { ! grep -q "^ *$1 = false" "$HOME/.config/hypr/custom/features.lua" 2>/dev/null; }
# Wallpaper Engine is off unless switched on in Settings › Extras (missing = off)
feature_on() { grep -q "^ *$1 = true" "$HOME/.config/hypr/custom/features.lua" 2>/dev/null; }

i=0
while [ $i -lt 60 ]; do
  hyprctl layers | grep -q "quickshell:background" && break
  sleep 1
  i=$((i+1))
done
echo "$(date +%T) shell background ready after $i s" >> "$log"
# Desktop check once the login has settled (replaces hypr-guard's login check): a notification only when something is
# wrong, e.g. no title bars after a Hyprland update or a shell built for an older Qt (~/.local/bin/phoenix-check)
[ -x "$HOME/.local/bin/phoenix-check" ] && (sleep 30; "$HOME/.local/bin/phoenix-check" health --notify >> "$log" 2>&1) &
# Setup profile steps that need a running desktop (wallpaper + colors after an install). No-op otherwise.
[ -x "$HOME/.local/bin/setup-profile" ] && "$HOME/.local/bin/setup-profile" first-login >> "$log" 2>&1
# First-time setup wizard after a fresh install (the clone installer leaves this marker; the wizard removes it)
if [ -f "$HOME/.local/state/setup-wizard/pending" ]; then
  echo "$(date +%T) opening the first-time setup wizard" >> "$log"
  qs -p "$HOME/.config/quickshell/end4-pC/setup-wizard.qml" > /dev/null 2>&1 &
fi

if feature_on wallpaperEngine; then
  echo "$(date +%T) starting wallpaper app" >> "$log"
  linux-wallpaper-engine-ux > /dev/null 2>&1 &

  i=0
  while [ $i -lt 30 ]; do
    pgrep -f "[l]inux-wallpaperengine" > /dev/null && break
    sleep 1
    i=$((i+1))
  done
  echo "$(date +%T) wallpaper renderer up after $i s" >> "$log"
else
  echo "$(date +%T) Wallpaper Engine background is switched off" >> "$log"
fi

# No background reload needed (since 2026-10-03): every wallpaper renderer now sits at or below the shell's
# background surface. Videos are drawn inside it; scenes run in linux-wallpaperengine with --layer background; web
# wallpapers run in wallpaper-engine-hyprland, patched to the background layer. See ~/.local/lib/wallpaper-engine-shell/.

# Phone Link (KDE Connect, set up with `phoenix phone-link setup`): its background service, like KDE Plasma starts it.
# With lock-screen sign-in it waits for the first unlock too (phone notifications shouldn't show before the password).
if command -v kdeconnectd >/dev/null && feature phoneLinkStart; then
  (
    wait_unlocked
    pgrep -x kdeconnectd >/dev/null || { echo "$(date +%T) starting kdeconnectd" >> "$log"; kdeconnectd >/dev/null 2>&1 & }
  ) &
fi

if feature steamTray; then
  (
    # With lock-screen sign-in, Steam waits for the first unlock too (2026-10-15): it shouldn't be signed in and
    # reachable (Remote Play / Steam Link) while the PC still sits at the lock screen.
    [ "${PHOENIX_LOCK_FIRST:-}" = 1 ] && echo "$(date +%T) steam waits for the first unlock" >> "$log"
    wait_unlocked
    echo "$(date +%T) starting steam" >> "$log"
    steam -silent > /dev/null 2>&1 &   # -silent: start in the tray, no window
  ) &
fi
# Your startup apps (Settings › Apps › Startup / Task Manager › Startup): after the first unlock too, each straight on
# its workspace (the shell used to start them on its own, before the password and once per boot only; 2026-10-16)
(
  wait_unlocked
  echo "$(date +%T) starting your startup apps" >> "$log"
  python3 "$HOME/.config/quickshell/end4-pC/scripts/hyprland/autostart.py" >> "$log" 2>&1
) &
echo "$(date +%T) done" >> "$log"
