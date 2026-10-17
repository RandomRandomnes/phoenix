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

    component PwField: Rectangle {
        property alias text: field.text
        property alias placeholder: field.placeholderText
        signal accepted()
        function focusIt() { field.forceActiveFocus() }
        implicitWidth: 260; implicitHeight: 36
        radius: 12
        color: Appearance.colors.colLayer4
        border.width: field.activeFocus ? 2 : 0
        border.color: Appearance.colors.colPrimary
        TextField {
            id: field
            anchors.fill: parent
            leftPadding: 10
            background: null
            echoMode: TextInput.Password
            placeholderTextColor: Appearance.colors.colSubtext
            color: Appearance.colors.colOnLayer3
            font.family: Appearance.font.family.main
            font.pixelSize: Appearance.font.pixelSize.small
            onAccepted: parent.accepted()
        }
    }
    id: page

    // "Administrator" only for members of wheel (the group sudo allows); it was shown for every account
    property bool isAdmin: true
    Connections { target: WState; function onRefreshTickChanged() { adminCheck.running = true } }
    Process {
        id: adminCheck
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
        // Change the password right here (2026-10-16; was a terminal window running passwd):
        // scripts/accounts/change-password.py answers passwd's questions; passwd's own reasons are shown when it refuses
        WCard {
            id: pwCard
            property bool open: false
            property string message: ""
            property bool messageOk: false
            icon: "password"
            title: "Change your password"
            description: pwCard.message !== "" ? pwCard.message : "Type the current password, then the new one twice"
            WButton {
                visible: !pwCard.open
                buttonText: "Change"
                onClicked: { pwCard.open = true; pwCard.message = ""; pwCur.forceActiveFocus() }
            }
        }
        ColumnLayout {
            visible: pwCard.open
            Layout.leftMargin: 56
            spacing: 8
            PwField { id: pwCur; placeholder: "Current password"; onAccepted: pwNew.focusIt() }
            PwField { id: pwNew; placeholder: "New password"; onAccepted: pwAgain.focusIt() }
            PwField { id: pwAgain; placeholder: "New password again"; onAccepted: pwChange.go() }
            RowLayout {
                spacing: 8
                WButton {
                    buttonText: "Cancel"
                    onClicked: { pwCard.open = false; pwCur.text = ""; pwNew.text = ""; pwAgain.text = ""; pwCard.message = "" }
                }
                WButton {
                    id: pwChange
                    accent: true
                    buttonText: pwProc.running ? "Changing…" : "Change password"
                    enabled: !pwProc.running && pwCur.text.length > 0 && pwNew.text.length > 0
                    function go() {
                        if (!enabled) return
                        if (pwNew.text !== pwAgain.text) { pwCard.message = "The new passwords don't match."; return }
                        pwProc.answer = pwCur.text + "\n" + pwNew.text + "\n"
                        pwProc.running = true
                    }
                    onClicked: go()
                }
            }
        }
        Process {
            id: pwProc
            property string answer: ""
            command: ["python3", Quickshell.shellPath("scripts/accounts/change-password.py")]
            stdinEnabled: true
            onStarted: { write(answer); answer = ""; stdinEnabled = false }
            stdout: StdioCollector {
                onStreamFinished: {
                    let r = { ok: false, message: "The password wasn't changed." }
                    try { r = JSON.parse(text) } catch (e) {}
                    pwCard.message = r.message
                    pwCard.messageOk = r.ok
                    if (r.ok) { pwCard.open = false; pwCur.text = ""; pwNew.text = ""; pwAgain.text = "" }
                    else pwCur.text = ""
                    pwProc.stdinEnabled = true
                }
            }
        }
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
            readonly property bool busy: Tasks.isRunning("login-screen")
            icon: "login"
            title: "Sign-in at startup"
            description: busy ? "Changing…"
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
            // a background job (2026-10-16; was a terminal): the password in the shell's own dialog, progress below
            function run(action) {
                Tasks.run("login-screen", ["bash", "-c", `~/.local/bin/phoenix login-screen ${action}`],
                    { title: "Sign-in at startup", askpassMessage: "Enter your password to change how the PC signs you in" })
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
            Connections { target: Tasks; function onFinished(id, ok) { if (id === "login-screen") loginScreen.refresh() } }
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
    WJob { jobId: "login-screen" }
}
