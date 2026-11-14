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
    property string previewStyle: ""      // the preview (modules/ii/lock/LockPreview.qml) shows a style without changing the setting
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
    Timer { id: disarm; interval: 5000; onTriggered: { root.switchArmed = false; root.desktopArmed = false; } }

    // Phoenix (2026-11-13): "Switch to KDE Plasma", left of "Switch user", in the login screen's desktop-chip look. Same
    // rules as Switch user (password first when "Require a password to shut down" is on, else a second click); then
    // KDE Plasma is remembered for the next sign-in and this desktop signs out (LockScreen.qml). Only where Plasma is
    // installed; this lock screen only runs under Hyprland, so the other desktop is always KDE Plasma.
    property bool plasmaInstalled: false
    property bool desktopArmed: false
    readonly property bool desktopPending: root.context.targetAction === LockContext.ActionEnum.SwitchDesktop
    Process {
        running: root.previewStyle === ""
        command: ["test", "-x", "/usr/bin/startplasma-wayland"]
        onExited: code => root.plasmaInstalled = code === 0
    }

    // password first, or two clicks within 5 s; a second click on a waiting chip cancels
    function chipClicked(action, armedProp) {
        if (Config.options.lock.security.requirePasswordToPower) {
            if (root.context.targetAction === action) root.context.resetTargetAction();
            else { root.context.targetAction = action; root.context.shouldReFocus(); }
        } else if (root[armedProp]) {
            root[armedProp] = false;
            root.context.unlocked(action);
        } else {
            root.switchArmed = false;
            root.desktopArmed = false;
            root[armedProp] = true;
            disarm.restart();
            root.context.shouldReFocus();
        }
    }

    Row {
        anchors { top: parent.top; right: parent.right; margins: 24 }
        z: 10
        spacing: 8
        visible: root.previewStyle === ""

        LockChip {
            id: switchDesktop
            visible: root.plasmaInstalled
            symbol: "desktop_windows"
            warn: root.desktopArmed || root.desktopPending
            label: root.desktopArmed ? Translation.tr("Click again to switch (apps close)")
                : root.desktopPending ? Translation.tr("Type your password to switch")
                : Translation.tr("Switch to KDE Plasma")
            onClicked: root.chipClicked(LockContext.ActionEnum.SwitchDesktop, "desktopArmed")
        }
        LockChip {
            id: switchUser
            visible: root.loginScreenOn
            symbol: "switch_account"
            warn: root.switchArmed || root.switchPending
            label: root.switchArmed ? Translation.tr("Click again to sign out (apps close)")
                : root.switchPending ? Translation.tr("Type your password to switch user")
                : Translation.tr("Switch user")
            onClicked: root.chipClicked(LockContext.ActionEnum.SwitchUser, "switchArmed")
        }
    }
}
