import QtQuick
import Quickshell
import Qt5Compat.GraphicalEffects
import qs
import qs.modules.common
import qs.modules.common.panels.lock
import qs.modules.ii.lock.styles

// Phoenix (2026-10-15): look at a lock screen style in a window, without locking the PC (Settings › Personalization ›
// Lock screen › Preview). `PHOENIX_LOCK_PREVIEW=<style> qs -p lock-preview.qml`. Nothing is real in here: no password
// check (no wrong-password lockout), no sleep / restart / shut down. Esc or closing the window ends it.
ShellRoot {
    FloatingWindow {
        id: win
        title: "Lock screen preview"
        implicitWidth: 1280
        implicitHeight: 720
        color: "black"
        onVisibleChanged: if (!visible) Qt.quit()

        Image {
            id: wallpaper
            anchors.fill: parent
            source: Config.options.background.wallpaperPath ? `file://${Config.options.background.wallpaperPath}` : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
        }
        FastBlur {   // like the real lock screen: the wallpaper, blurred
            anchors.fill: parent
            source: wallpaper
            radius: 64
        }
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.2)
        }
        LockContext {
            id: previewContext
            onUnlocked: action => {}   // never acted on in a preview
        }
        LockStyleLoader {
            anchors.fill: parent
            context: previewContext
            previewStyle: Quickshell.env("PHOENIX_LOCK_PREVIEW") || Config.options.lock.style || "islands"
            Keys.onEscapePressed: Qt.quit()
        }
        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 10
            width: previewLabel.implicitWidth + 24
            height: 28
            radius: 14
            color: Qt.rgba(0, 0, 0, 0.55)
            Text {
                id: previewLabel
                anchors.centerIn: parent
                text: "Preview — nothing you type here is checked · Esc closes"
                color: "white"
                font.pixelSize: 13
            }
        }
    }
}
