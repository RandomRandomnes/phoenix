pragma Singleton
import QtQuick
import Quickshell
import qs.modules.common

// Colors and sizes of the desktop menu (DesktopMenu.qml). Corners match the shell's own menus (StyledTextEditMenu:
// 16 px menu, 12 px rows; 2026-10-15) so it looks like the rest of the shell.
Singleton {
    readonly property color colMenu: Appearance.m3colors.m3surfaceContainer
    readonly property color colBorder: Appearance.colors.colOutlineVariant
    readonly property color colHover: Appearance.colors.colLayer2Hover
    readonly property color colPressed: Appearance.colors.colLayer2Active
    readonly property color colText: Appearance.m3colors.m3onSurface
    readonly property real rowHeight: 36
    readonly property real menuRadius: Appearance.rounding.small + 4
    readonly property real menuWidth: 264
}
