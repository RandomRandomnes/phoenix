import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.panels.lock

// Phoenix (2026-10-15): shows the lock screen in the style chosen in Settings (Config.options.lock.style).
// "original" (and anything unknown) is illogical-impulse's own LockSurface. Fail-safe: if a style can't be loaded
// (a QML error after an update, a missing file), the original lock screen is used, so there is always a password field.
Item {
    id: root
    required property LockContext context
    property string style: previewStyle !== "" ? previewStyle : (Config.options.lock.style ?? "original")
    property string previewStyle: ""      // lock-preview.qml shows a style without changing the setting
    readonly property var files: ({
        "islands": "LockStyleIslands.qml",
        "cookie": "LockStyleCookie.qml",
        "frosted": "LockStyleFrosted.qml",
        "hello": "LockStyleHello.qml",
        "editorial": "LockStyleEditorial.qml",
        "clock": "LockStyleClock.qml",
        "user": "LockStyleUser.qml",
        "bar": "LockStyleBar.qml",
        "plain": "LockStylePlain.qml",
    })
    readonly property url fallback: Qt.resolvedUrl("../LockSurface.qml")

    function load() {
        const file = root.files[root.style];
        if (file) loader.setSource(Qt.resolvedUrl(file), { context: root.context, preview: root.previewStyle !== "" });
        else if (root.previewStyle !== "") loader.sourceComponent = islandsNote;   // can't run in a preview window
        else loader.setSource(root.fallback, { context: root.context });
    }
    onStyleChanged: load()

    Component {
        id: islandsNote
        Item {
            Rectangle {
                anchors.centerIn: parent
                width: noteText.implicitWidth + 48
                height: noteText.implicitHeight + 32
                radius: 20
                color: Qt.rgba(0, 0, 0, 0.55)
                Text {
                    id: noteText
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    color: "white"
                    font.pixelSize: 16
                    text: "Original is illogical-impulse's own lock screen.\nIt can't be shown in a preview window: lock the screen with Super+L to see it."
                }
            }
        }
    }

    Loader {
        id: loader
        anchors.fill: parent
        focus: true
        // the original lock screen has real buttons and a real password check: in a preview it's only shown
        enabled: !(root.previewStyle !== "" && source === root.fallback)
        Component.onCompleted: root.load()
        onStatusChanged: {
            if (status === Loader.Error && source !== root.fallback) {
                console.warn(`[Lock] style "${root.style}" couldn't be loaded; using the original lock screen`);
                setSource(root.fallback, { context: root.context });
            }
        }
    }
}
