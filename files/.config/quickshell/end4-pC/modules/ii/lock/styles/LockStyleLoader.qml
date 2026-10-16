import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
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

    // Phoenix (2026-10-15): "Switch user" on every design, top right: signs out so another account (or another desktop
    // session) can sign in at the login screen. Only shown when the Phoenix login screen is on; without it, signing out
    // would sign the same account straight back in. Follows "Require a password to shut down" like the power buttons;
    // without it, a second click within 5 s confirms (open apps close).
    property bool loginScreenOn: false
    property bool switchArmed: false
    readonly property bool switchPending: root.context.targetAction === LockContext.ActionEnum.SwitchUser
    Process {
        running: root.previewStyle === ""
        command: ["grep", "-q", "phoenix-greeter", "/etc/greetd/config.toml"]
        onExited: code => root.loginScreenOn = code === 0
    }
    Timer { id: disarm; interval: 5000; onTriggered: root.switchArmed = false }

    RippleButton {
        id: switchUser
        visible: root.loginScreenOn && root.previewStyle === ""
        anchors { top: parent.top; right: parent.right; margins: 24 }
        z: 10
        implicitHeight: 44
        implicitWidth: switchRow.implicitWidth + 36
        buttonRadius: height / 2
        colBackground: root.switchArmed || root.switchPending ? Appearance.colors.colErrorContainer
            : ColorUtils.transparentize(Appearance.colors.colLayer0, 0.3)
        colBackgroundHover: root.switchArmed || root.switchPending ? Appearance.colors.colErrorContainerHover : Appearance.colors.colLayer1Hover
        onClicked: {
            if (Config.options.lock.security.requirePasswordToPower) {
                if (root.switchPending) root.context.resetTargetAction();
                else { root.context.targetAction = LockContext.ActionEnum.SwitchUser; root.context.shouldReFocus(); }
            } else if (root.switchArmed) {
                root.switchArmed = false;
                root.context.unlocked(LockContext.ActionEnum.SwitchUser);
            } else {
                root.switchArmed = true;
                disarm.restart();
                root.context.shouldReFocus();
            }
        }
        contentItem: Item {
            RowLayout {
                id: switchRow
                anchors.centerIn: parent
                spacing: 8
                MaterialSymbol {
                    text: "switch_account"
                    iconSize: 20
                    color: root.switchArmed || root.switchPending ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnLayer0
                }
                StyledText {
                    text: root.switchArmed ? Translation.tr("Click again to sign out (apps close)")
                        : root.switchPending ? Translation.tr("Type your password to switch user")
                        : Translation.tr("Switch user")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: root.switchArmed || root.switchPending ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnLayer0
                }
            }
        }
    }
}
