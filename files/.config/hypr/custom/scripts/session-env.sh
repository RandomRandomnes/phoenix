#!/bin/sh
# Phoenix (2026-10-15): give the session's environment to everything started through D-Bus or systemd (folder and file
# openers, portals, Dolphin's FileManager1 service), and clear what a KDE Plasma session before this one left there.
# illogical-impulse only updated D-Bus and, a second later, WAYLAND_DISPLAY + XDG_CURRENT_DESKTOP for systemd, so
# after switching from Plasma such helpers could still use Plasma's (gone) display and settings.
dbus-update-activation-environment --systemd --all 2>/dev/null
systemctl --user unset-environment KDE_FULL_SESSION KDE_SESSION_VERSION KDE_SESSION_UID KDE_APPLICATIONS_AS_SCOPE \
    XDG_SESSION_DESKTOP DESKTOP_SESSION 2>/dev/null
# helpers that are still running from before this Hyprland started hold the old environment: stop them, they start
# again on demand (D-Bus activation) with this session's
hypr_start=$(stat -c %Y "/proc/$(pgrep -x Hyprland | head -1)" 2>/dev/null || echo 0)
for u in xdg-desktop-portal.service xdg-desktop-portal-kde.service plasma-xdg-desktop-portal-kde.service \
         xdg-desktop-portal-gtk.service plasma-dolphin.service; do
    systemctl --user is-active -q "$u" || continue
    since=$(date -d "$(systemctl --user show "$u" -p ActiveEnterTimestamp --value)" +%s 2>/dev/null || echo 0)
    [ "$since" -lt "$hypr_start" ] && systemctl --user stop "$u"
done
exit 0
