// Phoenix's look for KDE Plasma's lock screen (2026-11-13; `phoenix kde-lock install`). Copied next to KDE's own
// lockscreen/LockScreenUi.qml and loaded over it by a two-line patch (LockScreenUi.patch). KDE's locker stays in
// charge: its authenticator (PAM) checks every password, and this file only hands the typed password to it, the way
// KDE's own MainBlock does. If this file fails to load, KDE's own lock screen shows underneath, still locked.
//
// The look is Phoenix's "Material islands" lock style: big clock, date and a "Locked" chip; along the bottom you, the
// password field and sleep / restart / shut down; top right "Switch to Phoenix" (and "Switch user" where KDE offers it).
// Colors, fonts and the wallpaper come from ~/.local/state/phoenix/kde-lock-theme.qml (phoenix-kde-lock-theme writes it
// at each Phoenix sign-in, from the same files the Phoenix login screen uses); without it KDE's colors are used.
//
// Switch to Phoenix / restart / shut down: the password first, always (like Phoenix with "Require a password to shut
// down"). After KDE's authenticator accepts it, LockScreenUi asks succeeded() before unlocking; for these actions it
// returns true, so the screen never unlocks: the action runs and the session ends behind the lock.
import QtCore
import QtQuick
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

Item {
    id: root

    // set by the Loader in LockScreenUi.qml
    property var ui: null            // lockScreenUi (pendingPassword)
    property var rootArea: null      // lockScreenRoot (uiVisible keeps KDE's authenticator awake)
    property var sessions: null      // SessionManagement (suspend, switchUser)

    // ── theme ──
    readonly property url themeUrl: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/state/phoenix/kde-lock-theme.qml"
    Loader { id: themeLoader; source: root.themeUrl }
    readonly property var t: themeLoader.item
    function c(name, fallback) { return (t && t.colors && t.colors[name]) ? t.colors[name] : fallback }
    readonly property color colPrimary: c("primary", Kirigami.Theme.highlightColor)
    readonly property color colOnPrimary: c("on_primary", Kirigami.Theme.highlightedTextColor)
    readonly property color colLayer0: c("background", Kirigami.Theme.backgroundColor)
    readonly property color colLayer1: c("surface_container_low", Kirigami.Theme.alternateBackgroundColor)
    readonly property color colField: c("surface_container_highest", Kirigami.Theme.alternateBackgroundColor)
    readonly property color colOnLayer0: c("on_background", Kirigami.Theme.textColor)
    readonly property color colOnLayer1: c("on_surface_variant", Kirigami.Theme.textColor)
    readonly property color colSubtext: c("outline", Kirigami.Theme.disabledTextColor)
    readonly property color colError: c("error", Kirigami.Theme.negativeTextColor)
    readonly property color colOnError: c("on_error", "white")
    readonly property color colErrorContainer: c("error_container", Kirigami.Theme.negativeBackgroundColor)
    readonly property color colOnErrorContainer: c("on_error_container", Kirigami.Theme.textColor)
    function alpha(col, a) { return Qt.rgba(col.r, col.g, col.b, a) }
    readonly property color colIsland: alpha(colLayer1, 0.85)
    readonly property string fontMain: (t && t.fontMain) || "Google Sans Flex"
    readonly property string fontExpressive: (t && t.fontExpressive) || fontMain
    readonly property string fontIcons: "Material Symbols Rounded"
    readonly property string clockFormat: (t && t.clockFormat) || "hh:mm"
    readonly property bool showLockedText: t ? t.showLockedText !== false : true
    readonly property string wallpaper: (t && t.wallpaper) || ""
    readonly property real k: Math.max(0.6, Math.min(width / 1280, height / 720)) * 0.81

    // ── state ──
    property string pending: ""      // "", "phoenix", "reboot", "poweroff": what the next accepted password does
    property bool busy: false
    property string status: ""       // shown in the field's place while empty
    property bool failedNow: false
    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    function wake() { if (root.rootArea) root.rootArea.uiVisible = true }
    function setPending(what) {
        root.pending = root.pending === what ? "" : what
        root.failedNow = false
        root.status = ""
        field.forceActiveFocus()
        root.wake()
    }
    function submit() {
        if (root.busy || field.text.length === 0) return
        root.busy = true
        root.failedNow = false
        root.status = ""
        authenticator.startAuthenticating()
        if (authenticator.pamTimeout) root.ui.pendingPassword = field.text
        else authenticator.respond(field.text)
    }
    // LockScreenUi.qml calls this when KDE accepted the password, before it unlocks. true = handled, stay locked.
    function succeeded() {
        if (root.pending === "") return false
        const cmd = root.pending === "phoenix" ? '"$HOME/.local/bin/switch-desktop" hyprland'
            : root.pending === "reboot" ? "systemctl reboot" : "systemctl poweroff"
        root.status = root.pending === "phoenix" ? "Switching to Phoenix…" : root.pending === "reboot" ? "Restarting…" : "Shutting down…"
        field.text = ""
        root.busy = true
        exec.connectSource(cmd)
        giveUp.restart()
        return true
    }
    Timer {   // the action didn't end the session (switch-desktop missing, logout refused): stay locked, say so
        id: giveUp
        interval: 20000
        onTriggered: {
            root.busy = false
            root.pending = ""
            root.status = "That didn't work. Unlock and try again from the desktop."
            root.failedNow = true
        }
    }
    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: source => exec.disconnectSource(source)
    }
    Connections {
        target: authenticator
        function onFailed(kind) {
            if (kind != 0) return     // fingerprint / smartcard: KDE's own notice
            root.busy = false
            root.failedNow = true
            // faillock and similar answer with an info message (in the system's language): show it as is
            root.status = authenticator.infoMessage || authenticator.errorMessage || "That password isn't right. Try again."
            field.text = ""
            shake.start()
        }
        function onPromptForSecretChanged() { Qt.callLater(() => field.forceActiveFocus()) }
    }

    // ── wallpaper: the login screen's copy, blurred like Phoenix's lock (none: KDE's own stays visible underneath) ──
    // drawn from the first frame (no fade from KDE's own lock screen): a solid backdrop whenever there is a wallpaper,
    // and the picture loaded before the first frame
    Rectangle { anchors.fill: parent; color: root.colLayer0; visible: root.wallpaper !== "" }
    Image {
        id: wall
        anchors.fill: parent
        source: root.wallpaper
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        sourceSize.width: root.width
        scale: 1.1
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 64; brightness: -0.1 }
    }
    MouseArea { anchors.fill: parent; onPressed: { root.wake(); field.forceActiveFocus() } }

    // ── clock, date, "Locked" ──
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 150 * root.k
        spacing: 4 * root.k
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(root.now, root.clockFormat)
            color: root.colPrimary
            font { family: root.fontExpressive; pixelSize: 168 * root.k; weight: Font.Medium; letterSpacing: -4 * root.k }
            height: 172 * root.k
            verticalAlignment: Text.AlignVCenter
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.locale().toString(root.now, "dddd, MMMM d")
            color: root.colOnLayer0
            font { family: root.fontMain; pixelSize: 26 * root.k }
        }
        Item { width: 1; height: 14 * root.k; visible: root.showLockedText }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.showLockedText
            width: lockedRow.implicitWidth + 32 * root.k
            height: 36 * root.k
            radius: height / 2
            color: root.alpha(root.colLayer1, 0.6)
            Row {
                id: lockedRow
                anchors.centerIn: parent
                spacing: 8 * root.k
                Text { anchors.verticalCenter: parent.verticalCenter; text: "lock"; color: root.colSubtext; font { family: root.fontIcons; pixelSize: 16 * root.k } }
                Text { anchors.verticalCenter: parent.verticalCenter; text: "Locked"; color: root.colSubtext; font { family: root.fontMain; pixelSize: 15 * root.k } }
            }
        }
    }

    // ── buttons ──
    component IconButton: Rectangle {
        id: ib
        property string symbol: ""
        property real size: 44 * root.k
        property color iconColor: root.colOnLayer1
        property color bg: "transparent"
        property bool toggled: false
        signal clicked()
        width: size; height: size; radius: size / 2
        color: toggled ? root.colErrorContainer : ibArea.containsMouse ? root.alpha(root.colOnLayer1, 0.12) : bg
        Text {
            anchors.centerIn: parent
            text: ib.symbol
            color: ib.toggled ? root.colOnErrorContainer : ib.iconColor
            font { family: root.fontIcons; pixelSize: ib.size * 0.46 }
        }
        MouseArea { id: ibArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ib.clicked() }
    }
    component Chip: Rectangle {
        id: chip
        property string symbol: ""
        property string label: ""
        property bool warn: false
        signal clicked()
        height: 44
        width: chipRow.implicitWidth + 36
        radius: height / 2
        color: warn ? root.colErrorContainer : chipArea.containsMouse ? root.alpha(root.colLayer1, 0.95) : root.alpha(root.colLayer0, 0.7)
        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: 8
            Text { anchors.verticalCenter: parent.verticalCenter; text: chip.symbol; color: chip.warn ? root.colOnErrorContainer : root.colOnLayer0; font { family: root.fontIcons; pixelSize: 20 } }
            Text { anchors.verticalCenter: parent.verticalCenter; text: chip.label; color: chip.warn ? root.colOnErrorContainer : root.colOnLayer0; font { family: root.fontMain; pixelSize: 15 } }
        }
        MouseArea { id: chipArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: chip.clicked() }
    }

    // top right: the same chips as Phoenix's lock screen
    Row {
        anchors { top: parent.top; right: parent.right; margins: 24 }
        spacing: 8
        Chip {
            symbol: "desktop_windows"
            warn: root.pending === "phoenix"
            label: warn ? "Type your password to switch" : "Switch to Phoenix"
            onClicked: root.setPending("phoenix")
        }
        Chip {
            visible: root.sessions ? root.sessions.canSwitchUser : false
            symbol: "switch_account"
            label: "Switch user"
            onClicked: root.sessions.switchUser()
        }
    }

    // ── the three islands ──
    Item {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 32 * root.k }
        height: 64 * root.k

        // you
        Rectangle {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            width: leftRow.implicitWidth + 26 * root.k
            height: 60 * root.k
            radius: height / 2
            color: root.colIsland
            Row {
                id: leftRow
                anchors { left: parent.left; leftMargin: 8 * root.k; verticalCenter: parent.verticalCenter }
                spacing: 12 * root.k
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44 * root.k; height: width; radius: width / 2
                    color: root.c("primary_container", root.colLayer1)
                    clip: true
                    Image {
                        id: face
                        anchors.fill: parent
                        source: kscreenlocker_userImage
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: width * 2
                        layer.enabled: true
                        layer.effect: MultiEffect { maskEnabled: true; maskSource: faceMask }
                    }
                    Rectangle { id: faceMask; anchors.fill: parent; radius: width / 2; visible: false; layer.enabled: true }
                    Text {
                        anchors.centerIn: parent
                        visible: face.status !== Image.Ready
                        text: "person"
                        color: root.c("on_primary_container", root.colOnLayer1)
                        font { family: root.fontIcons; pixelSize: 28 * root.k }
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: kscreenlocker_userName
                    color: root.colOnLayer1
                    font { family: root.fontMain; pixelSize: 16 * root.k; weight: Font.Medium }
                }
            }
        }

        // the password
        Rectangle {
            id: passIsland
            anchors.centerIn: parent
            width: centerRow.implicitWidth + 16 * root.k
            height: 64 * root.k
            radius: height / 2
            color: root.colIsland
            transform: Translate { id: shakeShift }
            SequentialAnimation {
                id: shake
                NumberAnimation { target: shakeShift; property: "x"; to: -24; duration: 50 }
                NumberAnimation { target: shakeShift; property: "x"; to: 24; duration: 50 }
                NumberAnimation { target: shakeShift; property: "x"; to: -12; duration: 40 }
                NumberAnimation { target: shakeShift; property: "x"; to: 12; duration: 40 }
                NumberAnimation { target: shakeShift; property: "x"; to: 0; duration: 30 }
            }
            Row {
                id: centerRow
                anchors.centerIn: parent
                spacing: 8 * root.k
                Rectangle {
                    width: 340 * root.k
                    height: 48 * root.k
                    radius: height / 2
                    color: root.colField
                    Text {
                        id: lockIcon
                        anchors { left: parent.left; leftMargin: 18 * root.k; verticalCenter: parent.verticalCenter }
                        text: "lock"
                        color: root.colSubtext
                        font { family: root.fontIcons; pixelSize: 18 * root.k }
                    }
                    TextInput {
                        id: field
                        anchors { left: lockIcon.right; right: parent.right; leftMargin: 12 * root.k; rightMargin: 18 * root.k; verticalCenter: parent.verticalCenter }
                        focus: true
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        color: root.colOnLayer1
                        selectionColor: root.colPrimary
                        font { family: root.fontMain; pixelSize: 15 * root.k }
                        clip: true
                        enabled: !root.busy
                        onTextChanged: { root.wake(); if (text.length > 0) root.failedNow = false }
                        onAccepted: root.submit()
                        Keys.onEscapePressed: event => {
                            if (root.pending !== "") { root.pending = ""; event.accepted = true }
                            else { text = ""; event.accepted = false }   // KDE: Esc turns the screen off
                        }
                        Component.onCompleted: forceActiveFocus()
                        Text {
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                            visible: field.text.length === 0
                            elide: Text.ElideRight
                            font: field.font
                            color: root.failedNow ? root.colError : root.colSubtext
                            text: root.busy && root.status === "" ? "Checking…"
                                : root.status !== "" ? root.status
                                : root.pending === "phoenix" ? "Password to switch to Phoenix"
                                : root.pending === "reboot" ? "Password to restart"
                                : root.pending === "poweroff" ? "Password to shut down"
                                : "Enter password"
                        }
                    }
                }
                IconButton {
                    size: 48 * root.k
                    symbol: root.pending === "poweroff" ? "power_settings_new" : root.pending === "reboot" ? "restart_alt"
                        : root.pending === "phoenix" ? "desktop_windows" : "arrow_forward"
                    iconColor: root.colOnPrimary
                    bg: root.colPrimary
                    onClicked: root.submit()
                }
            }
        }

        // sleep, restart, shut down
        Rectangle {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            width: rightRow.implicitWidth + 16 * root.k
            height: 60 * root.k
            radius: height / 2
            color: root.colIsland
            Row {
                id: rightRow
                anchors.centerIn: parent
                spacing: 4 * root.k
                IconButton {
                    visible: root.sessions ? root.sessions.canSuspend : false
                    symbol: "dark_mode"
                    onClicked: root.sessions.suspend()
                }
                IconButton { symbol: "restart_alt"; toggled: root.pending === "reboot"; onClicked: root.setPending("reboot") }
                IconButton {
                    symbol: "power_settings_new"
                    iconColor: root.colOnError
                    bg: root.colError
                    toggled: root.pending === "poweroff"
                    onClicked: root.setPending("poweroff")
                }
            }
        }
    }
}
