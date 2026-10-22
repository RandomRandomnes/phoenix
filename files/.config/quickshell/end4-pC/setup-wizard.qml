//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// First-time setup wizard (2026-10-03, ours; not upstream). Shown once after a fresh install: the clone installer
// leaves ~/.local/state/setup-wizard/pending and hypr/custom/scripts/autostart.sh opens this window (qs -p).
// Settings › Extras › "Run the first-time setup again" reopens it. Finishing or closing removes the marker.
// Steps reuse the Windows-style settings pages (modules/ii/settingsW11), ~/.local/bin/setup-profile (profiles) and
// ~/.local/bin/setup-apps (app catalog, drivers, updates; those run in the background, one after the other, and sudo
// asks for the password in the shell's own dialog via ~/.local/bin/phoenix-askpass — no terminal windows, 2026-10-16).
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.settingsW11

ApplicationWindow {
    id: root
    visible: true
    title: "Set up your PC"
    // fits small screens: on 1280×800 the 740 px window put its title bar under the taskbar (QA 2026-10-09)
    width: Math.min(1080, (Screen.width || 1920) - 40)
    height: Math.min(740, (Screen.height || 1080) - 160)
    minimumWidth: 780
    minimumHeight: 540
    color: Appearance.m3colors.m3background

    readonly property string home: Quickshell.env("HOME")
    readonly property string bin: `${home}/.local/bin`
    readonly property string pendingFile: `${home}/.local/state/setup-wizard/pending`
    // SETUP_WIZARD_DRYRUN=1: for testing on a live desktop; the profile step doesn't apply anything
    readonly property bool dryRun: Quickshell.env("SETUP_WIZARD_DRYRUN") === "1"
    // page/sub: a settingsW11 page embedded as the step body (WState.sub picks its sub-page)
    readonly property var steps: [
        { id: "welcome",   title: "Welcome",           icon: "waving_hand",
          heading: "Welcome to Phoenix",
          text: "Every step can be skipped and changed later in Settings (Super+I)" },
        { id: "wifi",      title: "Wi-Fi",             icon: "wifi", sub: "wifi",
          heading: "Network connection",
          text: "Pick a Wi-Fi network (not needed with a cable). Apps, drivers and updates need internet" },
        { id: "bluetooth", title: "Bluetooth",         icon: "bluetooth", sub: "bluetooth",
          heading: "Bluetooth devices",
          text: "Pair a mouse, keyboard, headphones or controller" },
        { id: "region",    title: "Time and region",   icon: "schedule", sub: "datetime",
          heading: "Time zone and weather",
          text: "Time zone, and the location for the taskbar weather" },
        { id: "keyboard",  title: "Keyboard",          icon: "keyboard", sub: "keyboard",
          heading: "Keyboard layout",
          text: "Layout and key repeat" },
        { id: "display",   title: "Display",           icon: "desktop_windows", sub: "display",
          heading: "Display",
          text: "Resolution, refresh rate and scale" },
        { id: "profile",   title: "Your setup",        icon: "tune",
          heading: "Setup profile",
          text: "Sets the look and which extra features are on" },
        { id: "colors",    title: "Colors",            icon: "palette", sub: "colors",
          heading: "Appearance",
          text: "Light or dark; colors follow the wallpaper" },
        { id: "wallpaper", title: "Wallpaper",         icon: "wallpaper", sub: "background",
          heading: "Wallpaper",
          text: "" },
        { id: "account",   title: "Account",           icon: "account_circle",
          heading: "User account",
          text: "Picture, name, password, and how the PC signs you in" },
        { id: "apps",      title: "Apps",              icon: "apps",
          heading: "Applications",
          text: "Firefox is already installed. Installing asks for your password" },
        { id: "system",    title: "Drivers and updates", icon: "memory",
          heading: "Drivers and updates",
          text: "Updates, graphics drivers and the boot menu" },
        { id: "shortcuts", title: "Shortcuts",         icon: "keyboard_command_key",
          heading: "Keyboard shortcuts",
          text: "Super is the Windows key. Super+/ shows every shortcut" },
        { id: "done",      title: "All set",           icon: "check_circle",
          heading: "Setup complete",
          text: "" },
    ]
    property int step: 0
    readonly property var cur: steps[step]

    // profile step
    property var profiles: []             // [{id, name, description}]
    property string chosen: "default"     // built-in id or a file path
    property string applied: ""
    property bool busy: false
    property string error: ""

    // apps step
    property var catalog: ({ groups: [], packs: [], apps: [] })
    property var installed: []            // ids
    property var picked: []               // ids
    property string appsStatus: ""
    property bool confirmingApps: false   // the "these apps will be installed" prompt
    signal nudgeRequested()   // the "custom fixes" question pulses when Next is pressed without an answer
    property var termQueue: []            // background jobs waiting for the current one to finish (F18)

    // internet: NetworkManager's connectivity check, every 5 s while the assistant is open, so connecting in the
    // Wi-Fi step enables the online actions right away. Steps that need it say so and don't start doomed installs.
    // "unknown" (check switched off) or no nmcli counts as online, so nothing is blocked by mistake.
    property bool online: true
    readonly property var onlineSteps: ["apps", "system"]
    readonly property string offlineNote: "No internet: connect in the Wi-Fi step, or do it later in Settings"

    // hardware
    property string gpuText: ""
    property bool needsDriver: false
    property bool laptop: false
    property string sysStatus: ""

    // startup (Drivers and updates step): ~/.local/bin/boot-loader; the computer starts without a boot menu by default
    property var boot: ({})
    property string bootChoice: ""
    readonly property var bootOptions: [
        { displayName: "No boot menu", value: "direct" },
        { displayName: "GRUB", value: "grub" },
        { displayName: "systemd-boot", value: "systemd-boot" },
        { displayName: "rEFInd", value: "refind" },
    ]
    readonly property string bootNote: {
        const c = root.bootChoice
        if (!root.online && (c === "grub" || c === "refind") && c !== root.boot.current) return `${c === "grub" ? "GRUB" : "rEFInd"} is downloaded when it is installed. ` + root.offlineNote
        if (root.boot.current === "other" && c === "direct") return "Something else starts first now. Apply to start Arch Linux directly"
        if (c === root.boot.current && c !== "direct") return "In use"
        if (c === "direct") return "No menu. Other systems start from the firmware boot menu (F8, F11 or F12)"
        if (c === "grub") return root.boot.secureBoot ? "Not available with Secure Boot on"
            : "Text menu: Arch Linux, fallback, Windows. Needs internet"
        if (c === "systemd-boot") return root.boot.windowsSeparate ? "Simple menu. Windows (separate partition) starts from the firmware menu"
            : "Simple menu: Arch Linux, fallback, Windows"
        if (c === "refind") return "Graphical menu that finds Arch Linux and Windows. Needs internet"
        return ""
    }

    // bug fixes consent (Drivers and updates step): must be answered, Yes or No, when a fixes source exists
    property var fixSource: ({})
    property string fixesAnswer: ""        // "yes" | "no"
    readonly property bool fixesQuestion: !!fixSource.repo
    readonly property bool blocked: root.cur.id === "system" && root.fixesQuestion && root.fixesAnswer === ""
    property bool fixesNudge: false        // Next was pressed without an answer: highlight the question
    function answerFixes(yes) {
        root.fixesNudge = false
        root.fixesAnswer = yes ? "yes" : "no"
        if (!root.dryRun) Config.options.extras.customFixes = yes
    }

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        // SETUP_WIZARD_STEP=<step id>: open at that step (testing)
        const start = root.steps.findIndex(st => st.id === Quickshell.env("SETUP_WIZARD_STEP"))
        if (start > 0) root.go(start)
    }
    onClosing: root.finish()

    function finish() {
        Quickshell.execDetached(["rm", "-f", root.pendingFile])
        Qt.quit()
    }
    function go(i) {
        root.error = ""
        root.step = Math.max(0, Math.min(root.steps.length - 1, i))
        if (root.cur.sub) WState.sub = root.cur.sub
        if (root.cur.id === "apps") installedProc.running = true
    }
    function next() {
        if (root.cur.id === "profile" && root.chosen !== root.applied) {
            if (root.chosen === "@file") { root.error = "Select a profile file first."; return }
            if (root.dryRun) {   // testing on a live desktop: pretend
                root.applied = root.chosen
                profileAppsProc.running = true
                root.go(root.step + 1)
                return
            }
            root.busy = true
            applyProc.running = true
            return
        }
        if (root.cur.id === "apps" && root.picked.length > 0 && !root.online) {   // offline: keep the picks, move on
            root.appsStatus = "Not installed: no internet. Retry after connecting, or later in Settings › Apps"
            root.go(root.step + 1)
            return
        }
        if (root.cur.id === "apps" && root.picked.length > 0) {   // also while a terminal is open: it queues (F18)
            root.confirmingApps = true
            return
        }
        if (root.cur.id === "done") {
            Quickshell.execDetached([`${root.bin}/phoenix-open`, "quickstart"])   // the guide app (a window of the shell)
            root.finish()
        } else root.go(root.step + 1)
    }
    function installPicked() {
        root.confirmingApps = false
        const ids = root.picked
        root.picked = []   // handed over; picking more later queues another installation
        root.appsStatus = termProc.running ? "Waiting for the current job"
                                           : "Installing in the background…"
        root.terminal([`${root.bin}/setup-apps`, "install", ...ids], "Installing applications")
        root.go(root.step + 1)
    }
    function appById(id) { return root.catalog.apps.find(a => a.id === id) || { id: id, name: id, icon: "apps" } }
    function togglePick(id) {
        const p = root.picked.slice()
        const i = p.indexOf(id)
        if (i >= 0) p.splice(i, 1); else p.push(id)
        root.picked = p
    }
    function packOn(pack) { return pack.apps.every(a => root.picked.includes(a) || root.installed.includes(a)) }
    function togglePack(pack) {
        const on = root.packOn(pack)
        let p = root.picked.filter(a => !pack.apps.includes(a))
        if (!on) p = p.concat(pack.apps.filter(a => !root.installed.includes(a)))
        root.picked = p
    }
    // runs a job in the background (2026-10-16; was a kitty window per job): one at a time, the others wait in
    // termQueue; sudo asks in the shell's password dialog (SUDO_ASKPASS)
    function terminal(args, title) {
        if (termProc.running) {   // one job at a time; starting a running Process again would drop the job
            root.termQueue = root.termQueue.concat([{ args: args, title: title }])
            return
        }
        termProc.jobTitle = title
        termProc.environment = { "SUDO_ASKPASS": `${root.bin}/phoenix-askpass`,
                                 "PATH": `${Quickshell.shellPath("scripts/askpass-bin")}:${Quickshell.env("PATH")}`,
                                 "PHOENIX_ASKPASS_MESSAGE": `Enter your password (${title.toLowerCase()})` }
        termProc.command = ["setsid", "-w"].concat(args)   // no terminal: sudo uses the password dialog (see services/Tasks.qml)
        termProc.running = true
    }

    // ── processes ──
    Process {
        id: netProc
        command: ["nmcli", "-t", "-f", "CONNECTIVITY", "general"]
        stdout: StdioCollector {
            onStreamFinished: { const c = text.trim(); root.online = c === "full" || c === "unknown" || c === "" }
        }
    }
    Timer {
        interval: 5000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: netProc.running = true
    }
    Process {
        id: listProc
        running: true
        command: [`${root.bin}/setup-profile`, "list"]
        stdout: StdioCollector {
            onStreamFinished: root.profiles = text.split("\n").filter(l => l.trim() !== "").map(l => {
                const m = l.match(/^(\S+)\s+([^:]+):\s*(.*)$/)
                return m ? { id: m[1], name: m[2], description: m[3] } : null
            }).filter(x => x)
        }
    }
    Process {
        id: applyProc
        command: [`${root.bin}/setup-profile`, "apply", root.chosen, "--yes"]
        stderr: StdioCollector { id: applyErr }
        onExited: (code, status) => {
            root.busy = false
            if (code === 0) {
                root.applied = root.chosen
                profileAppsProc.running = true
                root.go(root.step + 1)
            } else {
                root.error = applyErr.text.trim() || "The profile could not be applied."
            }
        }
    }
    Process {   // the chosen profile's apps are preselected on the Apps step
        id: profileAppsProc
        command: [`${root.bin}/setup-profile`, "apps", root.applied]
        stdout: StdioCollector {
            onStreamFinished: root.picked = text.split("\n").filter(l => l.trim() !== "")
        }
    }
    Process {
        id: filePicker
        command: [`${root.home}/.local/bin/phoenix-file-picker`, "open", root.home, "Setup profiles", "*.json"]
        stdout: StdioCollector { onStreamFinished: if (text.trim() !== "") root.chosen = text.trim() }
    }
    Process {
        id: catalogProc
        running: true
        command: [`${root.bin}/setup-apps`, "list"]
        stdout: StdioCollector {
            onStreamFinished: { try { root.catalog = JSON.parse(text) } catch (e) {} }
        }
    }
    Process {
        id: installedProc
        command: [`${root.bin}/setup-apps`, "installed"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.installed = text.split("\n").filter(l => l.trim() !== "")
                root.picked = root.picked.filter(a => !root.installed.includes(a))
            }
        }
    }
    Process {   // one background job at a time: app installs, drivers, updates
        id: termProc
        property string jobTitle: ""
        onExited: (code, status) => {
            root.appsStatus = root.appsStatus === "Installing in the background…"
                ? (code === 0 ? "Installed" : "Some apps couldn't be installed. Retry in Settings › Extras") : root.appsStatus
            root.sysStatus = root.sysStatus.endsWith("…") ? "Completed." : root.sysStatus
            installedProc.running = true
            bootProc.running = true
            if (root.termQueue.length > 0) {
                const job = root.termQueue[0]
                root.termQueue = root.termQueue.slice(1)
                if (job.title === "Installing applications") root.appsStatus = "Installing in the background…"
                root.terminal(job.args, job.title)
            }
        }
    }
    Process {
        id: bootProc
        running: true
        command: [`${root.bin}/boot-loader`, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.boot = JSON.parse(text) } catch (e) { root.boot = ({}) }
                // "other": the firmware starts something boot-loader doesn't manage (e.g. after a firmware reset); the
                // dropdown has no such option, so it offers the default (it showed "—" before)
                if (root.bootChoice === "" || root.bootChoice === "other")
                    root.bootChoice = root.boot.current && root.boot.current !== "other" ? root.boot.current : "direct"
            }
        }
    }
    Process {
        id: fixSourceProc
        running: true
        command: ["cat", `${root.home}/.local/share/custom-fixes/source.json`]
        stdout: StdioCollector { onStreamFinished: { try { root.fixSource = JSON.parse(text) } catch (e) { root.fixSource = ({}) } } }
    }
    Process {
        id: hwProc
        running: true
        command: ["bash", "-c", "lspci 2>/dev/null | grep -iE 'vga|3d|display' | sed 's/^[^:]*: //'; echo ---; ls /sys/class/power_supply 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("---")
                const gpus = parts[0].split("\n").filter(l => l.trim() !== "")
                root.gpuText = gpus.map(g => g.replace(/^.*?(VGA compatible controller|3D controller|Display controller):\s*/, "")
                    .replace(/\(rev [^)]*\)/, "").trim()).join("\n") || "Unknown graphics"
                const low = parts[0].toLowerCase()
                root.needsDriver = low.includes("nvidia") || low.includes("intel")
                root.laptop = (parts[1] || "").split("\n").some(l => /^BAT/.test(l.trim()))
            }
        }
    }

    // ── shared pieces ──
    component Choice: WCard {
        id: choice
        required property string value
        property bool picker: false      // the "profile file" card: opens the file picker instead
        readonly property bool selected: root.chosen === choice.value
        clickable: true
        onClicked: {
            if (choice.picker) filePicker.running = true
            else root.chosen = choice.value
        }
        MaterialSymbol {
            text: choice.selected ? "radio_button_checked" : "radio_button_unchecked"
            iconSize: 22
            color: choice.selected ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer2
        }
    }
    // An app's own icon (catalog "iconFile", next to apps.json); a symbol on a tile when it has none.
    component AppIcon: Item {
        id: appIcon
        required property var app
        property real size: 36
        implicitWidth: size
        implicitHeight: size
        Image {
            anchors.fill: parent
            visible: !!appIcon.app.iconFile
            source: appIcon.app.iconFile ? `file://${root.home}/.local/share/setup-profiles/${appIcon.app.iconFile}` : ""
            sourceSize: Qt.size(appIcon.size * 2, appIcon.size * 2)
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            asynchronous: true
        }
        Rectangle {
            anchors.fill: parent
            visible: !appIcon.app.iconFile
            radius: appIcon.size / 4
            color: Appearance.colors.colPrimaryContainer
            MaterialSymbol {
                anchors.centerIn: parent
                text: appIcon.app.icon
                iconSize: appIcon.size * 0.6
                fill: 1
                color: Appearance.colors.colOnPrimaryContainer
            }
        }
    }
    component AppCard: WCard {
        id: appCard
        required property var app
        readonly property bool isInstalled: root.installed.includes(app.id)
        readonly property bool isPicked: root.picked.includes(app.id)
        leading: Component { AppIcon { app: appCard.app } }
        title: app.name
        description: app.description
        clickable: !isInstalled
        onClicked: root.togglePick(app.id)
        StyledText {
            visible: appCard.isInstalled
            text: "Installed"
            color: Appearance.colors.colSubtext
        }
        MaterialSymbol {
            visible: !appCard.isInstalled
            text: appCard.isPicked ? "check_box" : "check_box_outline_blank"
            fill: appCard.isPicked ? 1 : 0
            iconSize: 22
            color: appCard.isPicked ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer2
        }
    }
    component Key: RowLayout {
        id: key
        required property string keys
        required property string what
        Layout.fillWidth: true
        spacing: 14
        Rectangle {
            Layout.preferredWidth: 190
            implicitHeight: 34
            radius: 12
            color: Appearance.colors.colLayer3
            StyledText {
                anchors.centerIn: parent
                text: key.keys
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer2
            }
        }
        StyledText {
            Layout.fillWidth: true
            text: key.what
            color: Appearance.colors.colOnLayer1
        }
    }

    // ── layout ──
    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {   // step list
            Layout.fillHeight: true
            Layout.preferredWidth: 250
            color: "transparent"   // Material look (2026-10-15): the list sits on the window background, like Settings' rail
            ColumnLayout {
                anchors { fill: parent; margins: 22 }
                spacing: 4
                StyledText {
                    text: "Set up your PC"
                    font.family: Appearance.font.family.expressive
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer0
                    Layout.bottomMargin: 12
                }
                Repeater {
                    model: root.steps
                    RippleButton {
                        id: stepButton
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        // shrinks a little on short windows (1280×800 screens) so all 14 steps fit
                        implicitHeight: Math.max(30, Math.min(40, (root.height - 120) / root.steps.length - 4))
                        buttonRadius: height / 2
                        colBackground: index === root.step ? Appearance.colors.colSecondaryContainer : "transparent"
                        colBackgroundHover: index === root.step ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colLayer1Hover
                        enabled: index <= root.step && !root.busy && !(root.blocked && index > root.step)
                        onClicked: root.go(index)
                        contentItem: RowLayout {
                            spacing: 12
                            opacity: stepButton.index <= root.step ? 1 : 0.5
                            MaterialSymbol {
                                Layout.leftMargin: 6
                                // offline: steps that need internet show "no connection" instead of their icon
                                text: stepButton.index < root.step ? "check_circle"
                                    : !root.online && root.onlineSteps.includes(stepButton.modelData.id) ? "cloud_off" : stepButton.modelData.icon
                                fill: stepButton.index <= root.step ? 1 : 0
                                iconSize: 20
                                color: stepButton.index === root.step ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer0
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: stepButton.modelData.title
                                elide: Text.ElideRight
                                font.weight: stepButton.index === root.step ? Font.DemiBold : Font.Normal
                                color: stepButton.index === root.step ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer0
                            }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }

        Rectangle {   // the page in one rounded panel (Material look, like Settings; 2026-10-15)
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 12
            Layout.rightMargin: 12
            Layout.bottomMargin: 12
            radius: Appearance.rounding.verylarge
            color: Appearance.colors.colLayer1
            clip: true

            ColumnLayout {   // current step
                anchors.fill: parent
                anchors.margins: 28
                anchors.leftMargin: 32
                spacing: 14

                StyledText {
                    text: root.cur.heading
                    font.pixelSize: Appearance.font.pixelSize.hugeass + 6
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer0
                }
                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    visible: text !== ""
                    text: root.cur.text
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
                }

                Loader {
                    id: body
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    sourceComponent: ({
                        welcome: welcomePage, wifi: networkPage, bluetooth: devicesPage, region: regionPage,
                        keyboard: devicesPage, display: systemPage, profile: profilePage, colors: personalizationPage,
                        wallpaper: personalizationPage, account: accountPage, apps: appsPage, system: hardwarePage,
                        shortcuts: shortcutsPage, done: donePage,
                    })[root.cur.id]
                }

                StyledText {
                    visible: root.error !== ""
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: root.error
                    color: Appearance.colors.colError
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    WButton {
                        visible: root.step > 0 && root.cur.id !== "done"
                        enabled: !root.busy
                        buttonText: "Back"
                        onClicked: root.go(root.step - 1)
                    }
                    Item { Layout.fillWidth: true }
                    WButton {
                        visible: root.cur.id !== "welcome" && root.cur.id !== "done" && root.cur.id !== "profile"
                            && !(root.cur.id === "system" && root.fixesQuestion)
                        buttonText: "Skip"
                        onClicked: root.go(root.step + 1)
                    }
                    StyledText {
                        visible: root.blocked && root.fixesNudge
                        text: "Select Yes or No above to continue"
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colError
                    }
                    WButton {
                        accent: true
                        enabled: !root.busy
                        buttonText: root.busy ? "Applying…" : root.cur.id === "welcome" ? "Get started"
                            : root.cur.id === "done" ? "Finish" : "Next"
                        onClicked: {
                            if (root.blocked) { root.fixesNudge = true; root.nudgeRequested(); return }
                            root.next()
                        }
                    }
                }
            }
        }
    }

    // ── step bodies ──
    Component {
        id: welcomePage
        Item {
            MaterialSymbol {
                anchors.centerIn: parent
                text: "desktop_windows"
                iconSize: 160
                color: Appearance.colors.colPrimary
                opacity: 0.85
            }
        }
    }
    // Recreated per step (Loader switches components), so WState.sub is read fresh each time.
    Component { id: networkPage; PNetwork {} }
    Component { id: devicesPage; PDevices {} }
    Component { id: systemPage; PSystem {} }
    Component { id: personalizationPage; PPersonalization {} }
    Component { id: accountPage; PAccounts { terminalRunner: root.terminal } }   // its terminal jobs join the queue (F18)
    Component {
        id: regionPage
        ColumnLayout {
            spacing: 10
            WCard {
                Layout.fillWidth: true
                Layout.rightMargin: 24   // line up with the PTime cards below (WPage leaves 24 px)
                icon: "partly_cloudy_day"
                title: "Weather on the taskbar"
                description: !Config.options.bar.weather.enable ? "Off"
                    : Config.options.bar.weather.enableGPS ? "Uses your location automatically"
                    : "City: " + (Config.options.bar.weather.city || "not set")
                StyledSwitch {
                    checked: Config.options.bar.weather.enable
                    onClicked: Config.options.bar.weather.enable = !Config.options.bar.weather.enable
                }
            }
            WCard {
                Layout.fillWidth: true
                Layout.rightMargin: 24
                visible: Config.options.bar.weather.enable
                icon: "location_on"
                title: "City"
                description: "Empty: found automatically"
                MaterialTextField {
                    Layout.preferredWidth: 220
                    placeholderText: "e.g. San Antonio"
                    text: Config.options.bar.weather.city
                    onEditingFinished: {
                        Config.options.bar.weather.city = text.trim()
                        Config.options.bar.weather.enableGPS = text.trim() === ""
                    }
                }
            }
            PTime {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
    Component {
        id: profilePage
        WPage {
            WSection {
                Repeater {
                    model: root.profiles
                    Choice {
                        required property var modelData
                        value: modelData.id
                        icon: modelData.id === "default" ? "desktop_windows" : "person"
                        title: modelData.name
                        description: modelData.description
                    }
                }
                Choice {
                    value: root.chosen.indexOf("/") >= 0 ? root.chosen : "@file"
                    picker: true
                    icon: "upload_file"
                    title: root.chosen.indexOf("/") >= 0 ? root.chosen.split("/").pop() : "Use a profile file…"
                    description: root.chosen.indexOf("/") >= 0 ? root.chosen : "A setup profile file (.json), for example from a USB drive"
                }
            }
        }
    }
    Component {
        id: appsPage
        WPage {
            WSection {
                title: "Application bundles"
                Repeater {
                    model: root.catalog.packs
                    WCard {
                        id: packCard
                        required property var modelData
                        readonly property bool on: root.packOn(modelData)
                        // the pack's apps as a row of overlapping icons
                        leading: Component {
                            Item {   // fixed width (5 icons) so the titles of all packs line up
                            implicitWidth: 34 + 4 * 24
                            implicitHeight: 34
                            Row {
                                spacing: -10
                                Repeater {
                                    model: packCard.modelData.apps.map(id => root.catalog.apps.find(a => a.id === id)).filter(a => a)
                                    AppIcon {
                                        required property var modelData
                                        app: modelData
                                        size: 34
                                    }
                                }
                            }
                            }
                        }
                        title: modelData.name
                        description: modelData.description
                        clickable: true
                        onClicked: root.togglePack(modelData)
                        MaterialSymbol {
                            text: packCard.on ? "check_box" : "check_box_outline_blank"
                            fill: packCard.on ? 1 : 0
                            iconSize: 22
                            color: packCard.on ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer2
                        }
                    }
                }
                WCard {
                    icon: "download"
                    title: root.picked.length === 0 ? "No applications selected" : `${root.picked.length} application${root.picked.length === 1 ? "" : "s"} selected`
                    description: root.picked.length === 0 ? (root.appsStatus || "Picked apps install when you press Next")
                        : !root.online ? root.picked.map(id => root.appById(id).name).join(", ") + ". " + root.offlineNote
                        : root.picked.map(id => root.appById(id).name).join(", ") + ". Installs when you press Next"
                }
            }
            Repeater {
                model: root.catalog.groups
                WSection {
                    id: groupSection
                    required property var modelData
                    title: modelData.name
                    Repeater {
                        model: root.catalog.apps.filter(a => a.group === groupSection.modelData.id)
                        AppCard {
                            required property var modelData
                            app: modelData
                        }
                    }
                }
            }
        }
    }
    Component {
        id: hardwarePage
        WPage {
            // Required question: highlighted box; Next without an answer turns it red and pulses it
            Rectangle {
                id: fixesBox
                visible: root.fixesQuestion
                Layout.fillWidth: true
                Layout.topMargin: 4
                implicitHeight: fixesCol.implicitHeight + 36
                radius: Appearance.rounding.normal
                color: Appearance.colors.colPrimaryContainer
                border.width: root.fixesNudge ? 3 : 2
                border.color: root.fixesNudge ? Appearance.colors.colError : Appearance.colors.colPrimary
                // the Next button is outside this page: it asks through root.nudgeRequested() (QA 2026-10-09: calling
                // nudgePulse directly was a ReferenceError)
                Connections { target: root; function onNudgeRequested() { nudgePulse.restart() } }
                SequentialAnimation {
                    id: nudgePulse
                    loops: 2
                    NumberAnimation { target: fixesBox; property: "scale"; to: 1.02; duration: 110 }
                    NumberAnimation { target: fixesBox; property: "scale"; to: 1.0; duration: 110 }
                }
                ColumnLayout {
                    id: fixesCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
                    spacing: 8
                    RowLayout {
                        spacing: 10
                        MaterialSymbol {
                            text: "build_circle"
                            fill: 1
                            iconSize: 26
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                        StyledText {
                            text: "Receive custom bug fixes?"
                            font.pixelSize: Appearance.font.pixelSize.larger
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                        Rectangle {   // "Required" chip
                            implicitWidth: requiredText.implicitWidth + 16
                            implicitHeight: requiredText.implicitHeight + 6
                            radius: height / 2
                            color: root.fixesNudge ? Appearance.colors.colError : Appearance.colors.colPrimary
                            StyledText {
                                id: requiredText
                                anchors.centerIn: parent
                                text: "Required"
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: Font.DemiBold
                                color: root.fixesNudge ? Appearance.colors.colOnError : Appearance.colors.colOnPrimary
                            }
                        }
                    }
                    StyledText {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: "Signed updates for the desktop shell and Phoenix's features, installed with regular updates. Your settings and files aren't touched. "
                            + "Without them the shell stays as it is. Changeable in Settings › Update"
                        color: Appearance.colors.colOnPrimaryContainer
                    }
                    RowLayout {
                        Layout.topMargin: 4
                        spacing: 10
                        WButton {
                            implicitWidth: 120
                            implicitHeight: 40
                            iconName: root.fixesAnswer === "yes" ? "check" : ""
                            buttonText: "Yes"
                            accent: root.fixesAnswer === "yes"
                            onClicked: root.answerFixes(true)
                        }
                        WButton {
                            implicitWidth: 120
                            implicitHeight: 40
                            iconName: root.fixesAnswer === "no" ? "check" : ""
                            buttonText: "No"
                            accent: root.fixesAnswer === "no"
                            onClicked: root.answerFixes(false)
                        }
                    }
                }
            }
            WSection {
                title: "Your PC"
                WCard {
                    icon: "memory"
                    title: "Graphics"
                    description: root.gpuText
                }
                WCard {
                    icon: "developer_board"
                    title: root.needsDriver ? "Graphics driver" : "Graphics driver: no action required"
                    description: root.needsDriver && !root.online ? "NVIDIA or Intel graphics. " + root.offlineNote
                        : root.needsDriver ? "NVIDIA or Intel graphics: install the driver, then restart"
                        : "AMD graphics work without a driver"
                    WButton {
                        visible: root.needsDriver
                        enabled: !termProc.running && root.online
                        buttonText: "Install driver"
                        onClicked: {
                            root.sysStatus = "Installing the graphics driver…"
                            root.terminal([`${root.bin}/setup-apps`, "run", "drivers"], "Graphics driver")
                        }
                    }
                }
                WCombo {
                    visible: root.laptop
                    icon: "battery_full"
                    title: "Power mode (laptop)"
                    model: [
                        { displayName: "Best battery life", value: PowerProfile.PowerSaver },
                        { displayName: "Balanced", value: PowerProfile.Balanced },
                    ].concat(PowerProfiles.hasPerformanceProfile ? [{ displayName: "Best performance", value: PowerProfile.Performance }] : [])
                    currentValue: PowerProfiles.profile
                    onSelected: v => PowerProfiles.profile = v
                }
            }
            WSection {
                title: "Startup"
                // only on the Phoenix image's boot layout; a system installed another way keeps its own boot setup
                visible: root.boot.uefi === true && root.boot.uki === true
                WCombo {
                    icon: "restart_alt"
                    title: "Boot menu"
                    description: root.bootNote
                    model: root.bootOptions
                    currentValue: root.bootChoice
                    fieldWidth: 170
                    onSelected: v => root.bootChoice = v
                    WButton {
                        enabled: !termProc.running && root.bootChoice !== root.boot.current
                            && !(root.bootChoice === "grub" && root.boot.secureBoot)
                            && (root.online || root.bootChoice === "direct" || root.bootChoice === "systemd-boot")   // GRUB/rEFInd are downloaded
                        buttonText: "Apply"
                        onClicked: {
                            root.terminal([`${root.bin}/boot-loader`, "use", root.bootChoice, "--yes"], "Boot menu")   // confirmed here
                        }
                    }
                }
            }
            WSection {
                title: "Updates"
                WCard {
                    icon: "system_update_alt"
                    title: "Install all updates"
                    description: root.sysStatus !== "" ? root.sysStatus : !root.online ? root.offlineNote
                        : "Recommended now. Asks for your password"
                    WButton {
                        accent: true
                        enabled: !termProc.running && root.online
                        buttonText: "Update now"
                        onClicked: {
                            root.sysStatus = "Installing updates…"
                            root.terminal([`${root.bin}/setup-apps`, "run", "update"], "Updates")
                        }
                    }
                }
            }
        }
    }
    Component {
        id: shortcutsPage
        WPage {
            WSection {
                title: "Everyday"
                Key { keys: "Super"; what: "Open the application menu and search" }
                Key { keys: "Super + Tab"; what: "Show all workspaces and windows" }
                Key { keys: "Super + Q"; what: "Close the active window" }
                Key { keys: "Super + D"; what: "Maximize or restore the active window" }
                Key { keys: "Super + L"; what: "Lock the screen" }
                Key { keys: "Super + I"; what: "Open Settings" }
            }
            WSection {
                title: "Apps"
                Key { keys: "Super + W"; what: "Web browser" }
                Key { keys: "Super + E"; what: "Files" }
                Key { keys: "Super + Enter"; what: "Terminal" }
            }
            WSection {
                title: "Shell"
                Key { keys: "Super + A"; what: "Left sidebar (AI chat, translator)" }
                Key { keys: "Super + N"; what: "Right sidebar (quick settings, notifications)" }
                Key { keys: "Super + V"; what: "Clipboard history" }
                Key { keys: "Super + ."; what: "Emoji" }
                Key { keys: "Super + Shift + S"; what: "Screenshot of an area" }
                Key { keys: "Ctrl + Super + T"; what: "Change the wallpaper" }
                Key { keys: "Super + /"; what: "Show all shortcuts" }
            }
        }
    }
    Component {
        id: donePage
        WPage {
            WSection {
                WCard {
                    icon: "menu_book"
                    title: "Phoenix Quick Start"
                    description: "Opens after Finish; also in the app menu"
                }
                WCard { icon: "settings"; title: "Settings"; description: "Super+I. Extra features are under Extras" }
                WCard { icon: "ios_share"; title: "Share your setup"; description: "Settings › Extras › Share my setup" }
            }
        }
    }

    // ── "these apps will be installed" prompt (Apps step, Next) ──
    Rectangle {
        anchors.fill: parent
        visible: root.confirmingApps
        color: Qt.rgba(0, 0, 0, 0.55)
        MouseArea { anchors.fill: parent; onClicked: root.confirmingApps = false }   // click outside = go back

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, 520)
            height: Math.min(parent.height - 80, confirmColumn.implicitHeight + 48)
            radius: Appearance.rounding.verylarge
            color: Appearance.colors.colLayer1Base   // opaque, like the shell's popups
            border.width: 1
            border.color: Appearance.colors.colLayer0Border
            MouseArea { anchors.fill: parent }   // clicks inside don't close it

            ColumnLayout {
                id: confirmColumn
                anchors { fill: parent; margins: 24 }
                spacing: 12
                StyledText {
                    text: `Install ${root.picked.length} application${root.picked.length === 1 ? "" : "s"}?`
                    font.family: Appearance.font.family.expressive
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer0
                }
                StyledText {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: "Installs in the background and asks for your password"
                    color: Appearance.colors.colSubtext
                }
                StyledFlickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Math.min(confirmList.implicitHeight, 300)
                    contentHeight: confirmList.implicitHeight
                    clip: true
                    ColumnLayout {
                        id: confirmList
                        width: parent.width
                        spacing: 8
                        Repeater {
                            model: root.confirmingApps ? root.picked.map(id => root.appById(id)) : []
                            RowLayout {
                                required property var modelData
                                spacing: 12
                                AppIcon { app: modelData; size: 30 }
                                StyledText {
                                    text: modelData.name
                                    font.weight: Font.DemiBold
                                    color: Appearance.colors.colOnLayer1
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    text: modelData.description || ""
                                    color: Appearance.colors.colSubtext
                                }
                            }
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    spacing: 10
                    Item { Layout.fillWidth: true }
                    WButton {
                        buttonText: "Cancel"
                        onClicked: root.confirmingApps = false
                    }
                    WButton {
                        accent: true
                        buttonText: "Install and continue"
                        onClicked: root.installPicked()
                    }
                }
            }
        }
    }
}
