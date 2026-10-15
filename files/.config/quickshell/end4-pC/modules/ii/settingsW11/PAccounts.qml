import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

WPage {
    // the setup assistant passes its terminal(args, title) so jobs wait for its open terminal window (one at a time)
    property var terminalRunner: null
    id: page

    // "Administrator" only for members of wheel (the group sudo allows); it was shown for every account
    property bool isAdmin: true
    Process {
        running: true
        command: ["id", "-nG"]
        stdout: StdioCollector { onStreamFinished: page.isAdmin = text.trim().split(/\s+/).includes("wheel") }
    }
    Process {
        id: pickProc
        command: [`${Quickshell.env("HOME")}/.local/bin/phoenix-file-picker`, "open", `${Quickshell.env("HOME")}/Pictures`, "Images", "*.png", "*.jpg", "*.jpeg", "*.webp", "*.gif"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim();
                if (!f) return;
                Config.options.profile.avatarPath = f.substring(0, f.lastIndexOf("/"));
                Config.options.profile.avatarPicture = f;
            }
        }
    }

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: 20
        UserAvatar {
            implicitWidth: 104
            implicitHeight: 104
        }
        ColumnLayout {
            spacing: 2
            StyledText {
                text: Config.options.profile.displayName || SystemInfo.username
                font.pixelSize: Appearance.font.pixelSize.hugeass
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer0
            }
            StyledText { text: `${SystemInfo.username}@${SystemInfo.hostname}`; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.small }
            StyledText { text: page.isAdmin ? "Local account · Administrator" : "Local account · Standard user"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.small }
        }
    }

    WSection {
        title: "Your info"
        WCard {
            icon: "photo_camera"
            title: "Choose a photo"
            description: "Shown on the lock screen, settings and sidebar"
            WButton { buttonText: "Browse files"; onClicked: pickProc.running = true }
            WButton {
                visible: Config.options.profile.avatarPicture !== ""
                buttonText: "Remove"
                onClicked: { Config.options.profile.avatarPicture = ""; Config.options.profile.avatarPath = ""; }
            }
        }
        WCard {
            icon: "badge"
            title: "Display name"
            description: `Leave empty to use your username (${SystemInfo.username})`
            Rectangle {
                implicitWidth: 240; implicitHeight: 34
                radius: 12
                color: Appearance.colors.colLayer4
                border.width: nameField.activeFocus ? 2 : 0
                border.color: Appearance.colors.colPrimary
                TextField {
                    id: nameField
                    anchors.fill: parent
                    leftPadding: 10
                    background: null
                    text: Config.options.profile.displayName
                    placeholderText: SystemInfo.username
                    placeholderTextColor: Appearance.colors.colSubtext
                    color: Appearance.colors.colOnLayer3
                    font.family: Appearance.font.family.main
                    font.pixelSize: Appearance.font.pixelSize.small
                    onEditingFinished: Config.options.profile.displayName = text.trim()
                }
            }
        }
        WCombo {
            icon: "short_text"
            title: "Subtitle under your name"
            model: [{ displayName: "Distribution name", value: "::distro::" }, { displayName: "Uptime", value: "::uptime::" }]
            currentValue: Config.options.profile.descriptionText
            onSelected: v => Config.options.profile.descriptionText = v
        }
    }

    WSection {
        title: "Account settings"
        // its own centered terminal in front (class phoenix-setup, custom/rules.lua); the stock "kitty -1" could reuse
        // an open kitty window, and from the setup assistant it could open behind it
        WLink { icon: "password"; title: "Change your password"; description: "Opens a window that asks for the current password, then the new one twice"; chevronIcon: "open_in_new"
                // through the setup assistant's queue when it runs there (one terminal at a time; QA 2026-10-08)
                action: () => terminalRunner ? terminalRunner(["bash", "-c", "passwd; echo; read -r -p 'Press Enter to close.'"], "Change password")
                    : Quickshell.execDetached(["kitty", "--class", "phoenix-setup", "--title", "Change password", "--hold", "passwd"]) }
        // Phoenix sign-in at startup (P5 2026-10-08; lock-screen mode 2026-10-15): `phoenix login-screen install --mode
        // lock|greeter` / `remove` in a terminal (asks for the password). Lock screen = the desktop starts behind the lock
        // screen (greetd autologin into a locked session); login screen = the full Phoenix login screen; off = automatic.
        WCombo {
            id: loginScreen
            property string lsState: ""   // "on" | "off" | ""
            property string lsMode: "greeter"   // when on: "lock" | "greeter"
            property string otherDm: ""   // another login manager (sddm, gdm…) instead of automatic sign-in
            property bool updateReady: false   // a newer login screen came with a Phoenix update (root's copy is older)
            // busy also while the assistant's terminal runs it (lsRecheck), so it can't be queued twice
            readonly property bool busy: lsChange.running || lsRecheck.running
            icon: "login"
            title: "Sign-in at startup"
            description: busy ? "Waiting for the window that asks for your password…"
                : lsState === "on" ? (lsMode === "lock"
                        ? "Lock screen: your desktop starts behind it, so it's ready as soon as you type your password"
                        : "Login screen: the PC starts at the Phoenix login screen and asks for your password")
                    + (updateReady ? ". An update is ready" : "")
                : lsState === "off" ? (otherDm ? `Off: the PC uses another login screen (${otherDm})` : "Off: the PC signs you in automatically, no password")
                : "Checking…"
            model: [
                { displayName: "Lock screen (fastest)", value: "lock" },
                { displayName: "Login screen", value: "greeter" },
                { displayName: "Off (no password)", value: "off" },
            ]
            currentValue: lsState === "" ? "" : lsState === "off" ? "off" : lsMode
            enabled: lsState !== "" && !busy
            onSelected: v => {
                if (v === loginScreen.currentValue) return
                loginScreen.run(v === "off" ? "remove" : `install --mode ${v}`)
            }
            function run(action) {
                const args = ["bash", "-c", `~/.local/bin/phoenix login-screen ${action}; echo; read -r -p 'Press Enter to close.'`]
                if (terminalRunner) { terminalRunner(args, "Sign-in at startup"); lsRecheck.restart(); return }
                lsChange.command = ["kitty", "--class", "phoenix-setup", "--title", "Sign-in at startup", "--"].concat(args)
                lsChange.running = true
            }
            function refresh() { lsStatus.running = true }
            Component.onCompleted: refresh()
            Connections { target: GlobalStates; function onSettingsOpenChanged() { if (GlobalStates.settingsOpen) loginScreen.refresh() } }
            Process {
                id: lsStatus
                command: ["bash", "-c", "~/.local/bin/phoenix login-screen status"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        loginScreen.lsState = /: on/.test(text) ? "on" : /: off/.test(text) ? "off" : ""
                        loginScreen.lsMode = /mode: lock screen/.test(text) ? "lock" : "greeter"
                        loginScreen.otherDm = (text.match(/login manager: ([\w.-]+)/) || [])[1] ?? ""
                        loginScreen.updateReady = /update is ready/.test(text)
                    }
                }
            }
            Process {
                id: lsChange
                onExited: loginScreen.refresh()
            }
            Timer {   // through the assistant's terminal: look again every few seconds for a while
                id: lsRecheck
                interval: 3000; repeat: true
                property int left: 0
                property string startState: ""
                onRunningChanged: if (running) { left = 60; startState = loginScreen.lsState + loginScreen.lsMode }
                onTriggered: { loginScreen.refresh(); if (--left <= 0 || loginScreen.lsState + loginScreen.lsMode !== startState) stop() }
            }
            WButton {   // an update for the installed login screen: install again (keeps the mode)
                visible: loginScreen.lsState === "on" && loginScreen.updateReady
                accent: true
                enabled: !loginScreen.busy
                buttonText: "Update"
                onClicked: loginScreen.run("install")
            }
        }
        WLink { icon: "key"; title: "Sign-in options"; description: "Lock screen, keyring, password requirements"; page: "privacy" }
        WLink { icon: "group"; title: "Other users"; description: "Add or manage user accounts"; chevronIcon: "open_in_new"; action: () => Quickshell.execDetached(["bash", "-c", Config.options.apps.manageUser]) }
    }
}
