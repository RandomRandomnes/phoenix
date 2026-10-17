import QtQuick
import Quickshell
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import qs
import qs.modules.common
import qs.modules.common.panels.lock
import qs.modules.ii.lock.styles

// Look at a lock screen style in a window, without locking the PC (Settings › Personalization › Lock screen › Preview).
// A window of the shell since 2026-10-16 (was a separate `qs -p lock-preview.qml` program that started without the
// shell's theme): `qs ipc call lockPreview open <style>`. Nothing is real in here: no password check (no wrong-password
// lockout), no sleep / restart / shut down. Esc or closing the window ends it.
Scope {
    id: root
    property bool open: false
    property string style: ""

    IpcHandler {
        target: "lockPreview"
        function open(style: string): void { root.style = style; root.open = true; }
        function close(): void { root.open = false; }
    }

    Loader {
        active: root.open
        sourceComponent: FloatingWindow {
            title: "Lock screen preview"
            implicitWidth: 1280
            implicitHeight: 720
            color: "black"
            visible: true
            onVisibleChanged: if (!visible) root.open = false

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
                previewStyle: root.style || Config.options.lock.style || "islands"
                Keys.onEscapePressed: root.open = false
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
}
