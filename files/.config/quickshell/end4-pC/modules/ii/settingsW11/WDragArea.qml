import QtQuick
import Quickshell

// Phoenix (2026-10-15): the Settings window has no system title bar (hypr/custom/rules.lua "settings-no-titlebar"):
// drag this area to move it (Wayland interactive move), double-click to maximize / restore. The move starts only
// once the mouse moves, so a double-click still reaches onDoubleClicked.
MouseArea {
    property point pressAt
    onPressed: mouse => pressAt = Qt.point(mouse.x, mouse.y)
    onPositionChanged: mouse => {
        if (pressed && Math.abs(mouse.x - pressAt.x) + Math.abs(mouse.y - pressAt.y) > 4)
            Window.window.startSystemMove()
    }
    onDoubleClicked: Quickshell.execDetached(["hyprctl", "dispatch",
        'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })'])
}
