//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Phoenix Task Manager (2026-10-15, ours; not upstream). Started by ~/.local/bin/phoenix-task-manager (Ctrl+Shift+Esc,
// the session menu, Settings › Apps › Task manager, the app menu). The Settings "Material rail" look: sections on a rail,
// the page in one rounded panel. Data: scripts/taskmanager/procs.py (processes, grouped into apps / background /
// system, live CPU, memory, GPU and disk) and scripts/sysstats/sysstats.py (the bar's system stats).
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.settingsW11

ApplicationWindow {
    id: root
    visible: true
    title: "Task Manager"
    width: Math.min(1240, (Screen.width || 1920) - 40)
    height: Math.min(820, (Screen.height || 1080) - 120)
    minimumWidth: 860
    minimumHeight: 560
    color: Appearance.m3colors.m3background

    readonly property var sections: [
        { id: "processes", name: "Processes", icon: "view_list" },
        { id: "performance", name: "Performance", icon: "monitoring" },
        { id: "startup", name: "Startup", icon: "rocket_launch" },
        { id: "services", name: "Services", icon: "settings_applications" },
        { id: "users", name: "Users", icon: "group" },
    ]
    property string page: "processes"
    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        const p = Quickshell.env("TASK_MANAGER_PAGE")
        if (root.sections.some(s => s.id === p)) root.page = p
    }

    // ── data ────────────────────────────────────────────────────────────────────────────────────────────────────────
    property var totals: ({})
    property var groups: []
    property var stats: ({})
    readonly property int histLen: 60
    property var cpuHist: []
    property var memHist: []
    property var gpuHist: []
    property var diskHist: []
    property var netHist: []
    property real netPeak: 1
    property real diskPeak: 1

    function push(arr, v) { const a = arr.concat([Math.max(0, Math.min(1, v))]); return a.length > root.histLen ? a.slice(a.length - root.histLen) : a }

    Process {
        running: true
        command: ["python3", Quickshell.shellPath("scripts/taskmanager/procs.py"), "1.5"]
        stdout: SplitParser {
            onRead: line => {
                let d
                try { d = JSON.parse(line) } catch (e) { return }
                root.totals = d.totals
                root.groups = d.groups
                root.memHist = root.push(root.memHist, (d.totals.mem ?? 0) / 100)
                const disk = (d.totals.diskRead ?? 0) + (d.totals.diskWrite ?? 0)
                root.diskPeak = Math.max(root.diskPeak * 0.98, disk, 1)
                root.diskHist = root.push(root.diskHist, (d.totals.diskBusy ?? 0) / 100)
                root.checkPending()
            }
        }
    }
    Process {
        running: true
        command: ["python3", Quickshell.shellPath("scripts/sysstats/sysstats.py"), "1.5"]
        stdout: SplitParser {
            onRead: line => {
                let d
                try { d = JSON.parse(line) } catch (e) { return }
                root.stats = d
                root.cpuHist = root.push(root.cpuHist, d.cpu?.usage ?? 0)
                root.gpuHist = root.push(root.gpuHist, d.gpu?.busy ?? 0)
                const net = (d.net?.rx ?? 0) + (d.net?.tx ?? 0)
                root.netPeak = Math.max(root.netPeak * 0.98, net, 1024)
                root.netHist = root.push(root.netHist, net / root.netPeak)
            }
        }
    }

    // ── formatting ──────────────────────────────────────────────────────────────────────────────────────────────────
    function bytes(b) {
        if (b === undefined || b === null) return "—"
        if (b >= 1073741824) return (b / 1073741824).toFixed(1) + " GB"
        if (b >= 1048576) return Math.round(b / 1048576) + " MB"
        return Math.round(b / 1024) + " KB"
    }
    function rate(b) {
        if (!b) return "0 MB/s"
        if (b >= 1048576) return (b / 1048576).toFixed(1) + " MB/s"
        return (b / 1024).toFixed(0) + " KB/s"
    }
    function pct(v) { return (v ?? 0).toFixed(1) + "%" }
    function duration(s) {
        s = Math.floor(s || 0); const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60)
        return (d ? d + " d " : "") + h + " h " + m + " min"
    }
    // friendlier names for the desktop's own programs
    readonly property var friendly: ({
        "qs": "Desktop shell (Quickshell)", "quickshell": "Desktop shell (Quickshell)", "Hyprland": "Hyprland (desktop)",
        "Xwayland": "Xwayland (older apps)", "pipewire": "PipeWire (sound)", "pipewire-pulse": "PipeWire (sound, Pulse)",
        "wireplumber": "WirePlumber (sound)", "xdg-desktop-por": "Desktop portal", "steamwebhelper": "Steam (web helper)",
        "electron": "Electron app helpers", "kitty": "kitty", "systemd": "systemd (your services)", "dbus-broker": "D-Bus",
        "dbus-daemon": "D-Bus", "gnome-keyring-d": "Keyring", "hypridle": "Idle and sleep", "hyprsunset": "Night light",
        "start-hyprland": "Hyprland start-up", "NetworkManager": "Network Manager", "bluetoothd": "Bluetooth",
        "wpa_supplicant": "Wi-Fi", "systemd-journal": "System log", "systemd-logind": "Sign-in sessions",
        "systemd-udevd": "Device manager", "systemd-resolve": "Name lookups (DNS)", "greetd": "Login screen",
        "polkitd": "Permissions (polkit)", "upowerd": "Power and batteries", "cupsd": "Printing", "sshd": "SSH server",
    })
    function label(g) { return g.kind === "app" ? g.name : (root.friendly[g.name] ?? g.name) }
    // ending these closes or breaks your session: ask twice
    readonly property var critical: ["qs", "quickshell", "Hyprland", "start-hyprland", "Xwayland", "systemd", "dbus-broker",
        "dbus-daemon", "greetd", "systemd-logind", "pipewire", "wireplumber"]

    // ── Processes state ─────────────────────────────────────────────────────────────────────────────────────────────
    property string search: ""
    property string sortKey: "cpu"
    property bool sortDesc: true
    property string selectedKey: ""
    property bool showSystem: false
    readonly property var selected: root.groups.find(g => g.key === root.selectedKey) ?? null
    function sorted(kind) {
        const q = root.search.trim().toLowerCase()
        let l = root.groups.filter(g => g.kind === kind)
        if (q) l = l.filter(g => root.label(g).toLowerCase().includes(q) || g.name.toLowerCase().includes(q)
            || String(g.pid).startsWith(q) || (g.cls ?? "").toLowerCase().includes(q))
        const k = root.sortKey, dir = root.sortDesc ? -1 : 1
        return l.sort((a, b) => k === "name" ? dir * root.label(a).localeCompare(root.label(b)) : dir * ((a[k] ?? 0) - (b[k] ?? 0)))
    }
    readonly property var appProcs: sorted("app")
    readonly property var bgProcs: sorted("background")
    readonly property var sysProcs: sorted("system")

    // End task: TERM now; if it's still there after 4 s, offer Force end (KILL). Other users' processes: pkexec.
    property var pending: null          // { key, name, pids, own, at }
    property bool forceOffer: false
    property bool confirmArmed: false
    Timer { id: disarm; interval: 5000; onTriggered: root.confirmArmed = false }
    function endTask(force) {
        const g = root.selected
        if (!g) return
        if (!force && root.critical.includes(g.name) && !root.confirmArmed) { root.confirmArmed = true; disarm.restart(); return }
        root.confirmArmed = false
        const sig = force ? "-KILL" : "-TERM"
        const pids = g.pids.map(String)
        Quickshell.execDetached(g.own ? ["kill", sig].concat(pids) : ["pkexec", "kill", sig].concat(pids))
        root.pending = { key: g.key, name: root.label(g), pids: g.pids, own: g.own, at: Date.now() }
        root.forceOffer = false
    }
    function checkPending() {
        if (!root.pending) return
        const alive = root.groups.some(g => g.pids.some(p => root.pending.pids.includes(p)))
        if (!alive) { root.pending = null; root.forceOffer = false; return }
        if (Date.now() - root.pending.at > 4000) root.forceOffer = true
    }
    function forceEnd() {
        if (!root.pending) return
        const pids = root.pending.pids.map(String)
        Quickshell.execDetached(root.pending.own ? ["kill", "-KILL"].concat(pids) : ["pkexec", "kill", "-KILL"].concat(pids))
        root.pending.at = Date.now()
        root.forceOffer = false
    }

    // ── layout ──────────────────────────────────────────────────────────────────────────────────────────────────────
    RowLayout {
        anchors.fill: parent
        spacing: 0

        ColumnLayout {   // rail
            Layout.fillHeight: true
            Layout.preferredWidth: 96
            Layout.maximumWidth: 96
            spacing: 2
            Item { implicitHeight: 16 }
            RippleButton {   // run a new task
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 14
                implicitWidth: 56
                implicitHeight: 56
                buttonRadius: Appearance.rounding.normal
                colBackground: Appearance.colors.colPrimaryContainer
                colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                colRipple: Appearance.colors.colPrimaryContainerActive
                onClicked: runDialog.visible = !runDialog.visible
                contentItem: MaterialSymbol {
                    text: "add"
                    iconSize: 24
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: Appearance.colors.colOnPrimaryContainer
                }
                StyledToolTip { text: "Run new task" }
            }
            Repeater {
                model: root.sections
                Item {
                    id: navItem
                    required property var modelData
                    readonly property bool current: root.page === modelData.id
                    Layout.fillWidth: true
                    implicitHeight: 54
                    MouseArea {
                        id: navMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.page = navItem.modelData.id
                    }
                    Rectangle {
                        id: pill
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 2
                        width: navItem.current || navMouse.containsMouse ? 56 : 32
                        height: 32
                        radius: 16
                        color: navItem.current ? Appearance.colors.colSecondaryContainer
                            : navMouse.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"
                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: navItem.modelData.icon
                            iconSize: 22
                            fill: navItem.current ? 1 : 0
                            color: navItem.current ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer0
                        }
                    }
                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: pill.bottom
                        anchors.topMargin: 3
                        text: navItem.modelData.name
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: navItem.current ? Font.DemiBold : Font.Normal
                        color: navItem.current ? Appearance.colors.colOnLayer0 : Appearance.colors.colSubtext
                    }
                }
            }
            Item { Layout.fillHeight: true }
        }

        Rectangle {   // page panel
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 12
            Layout.rightMargin: 12
            Layout.bottomMargin: 12
            radius: Appearance.rounding.verylarge
            color: Appearance.colors.colLayer1
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 32
                anchors.rightMargin: 24
                anchors.topMargin: 22
                anchors.bottomMargin: 18
                spacing: 16

                RowLayout {   // header
                    Layout.fillWidth: true
                    spacing: 14
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        StyledText {
                            text: "Task Manager"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                        StyledText {
                            text: root.sections.find(s => s.id === root.page)?.name ?? ""
                            font.family: Appearance.font.family.expressive
                            font.pixelSize: 40
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnLayer1
                        }
                    }
                    Rectangle {   // search (Processes)
                        visible: root.page === "processes"
                        implicitWidth: 280
                        implicitHeight: 48
                        radius: 24
                        color: Appearance.colors.colLayer2
                        border.width: searchField.activeFocus ? 2 : 0
                        border.color: Appearance.colors.colPrimary
                        RowLayout {
                            anchors { fill: parent; leftMargin: 18; rightMargin: 16 }
                            spacing: 10
                            MaterialSymbol { text: "search"; iconSize: 20; color: Appearance.colors.colSubtext }
                            TextField {
                                id: searchField
                                Layout.fillWidth: true
                                placeholderText: "Search by name or PID"
                                placeholderTextColor: Appearance.colors.colSubtext
                                color: Appearance.colors.colOnLayer1
                                font.family: Appearance.font.family.main
                                font.pixelSize: Appearance.font.pixelSize.small
                                background: null
                                selectByMouse: true
                                onTextChanged: root.search = text
                                Keys.onEscapePressed: text = ""
                            }
                        }
                    }
                    RippleButton {   // End task
                        visible: root.page === "processes"
                        enabled: root.selected !== null
                        opacity: enabled ? 1 : 0.45
                        implicitHeight: 48
                        implicitWidth: endText.implicitWidth + 44
                        buttonRadius: 24
                        colBackground: Appearance.colors.colErrorContainer
                        colBackgroundHover: Appearance.colors.colErrorContainerHover
                        colRipple: Appearance.colors.colErrorContainerActive
                        onClicked: root.endTask(false)
                        contentItem: Item {
                            StyledText {
                                id: endText
                                anchors.centerIn: parent
                                text: root.confirmArmed ? "Click again: this closes part of your desktop" : (root.selected && !root.selected.own ? "End task (asks for your password)" : "End task")
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnErrorContainer
                            }
                        }
                    }
                }

                // Run new task
                Rectangle {
                    id: runDialog
                    visible: false
                    Layout.fillWidth: true
                    implicitHeight: 64
                    radius: Appearance.rounding.large
                    color: Appearance.colors.colLayer3
                    RowLayout {
                        anchors { fill: parent; leftMargin: 20; rightMargin: 12 }
                        spacing: 12
                        MaterialSymbol { text: "terminal"; iconSize: 22; color: Appearance.colors.colOnLayer3 }
                        TextField {
                            id: runField
                            Layout.fillWidth: true
                            placeholderText: "Program or command to run, e.g. firefox"
                            placeholderTextColor: Appearance.colors.colSubtext
                            color: Appearance.colors.colOnLayer3
                            font.family: Appearance.font.family.main
                            font.pixelSize: Appearance.font.pixelSize.small
                            background: null
                            selectByMouse: true
                            onVisibleChanged: if (visible) forceActiveFocus()
                            Keys.onReturnPressed: runButton.clicked()
                            Keys.onEscapePressed: runDialog.visible = false
                        }
                        WButton {
                            id: runButton
                            accent: true
                            buttonText: "Run"
                            onClicked: {
                                if (runField.text.trim() === "") return
                                Quickshell.execDetached(["bash", "-c", runField.text])
                                runField.text = ""
                                runDialog.visible = false
                            }
                        }
                    }
                }

                Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    sourceComponent: ({ processes: processesPage, performance: performancePage, startup: startupPage,
                        services: servicesPage, users: usersPage })[root.page]
                }
            }
        }
    }

    // ── Processes ───────────────────────────────────────────────────────────────────────────────────────────────────
    readonly property var columns: [
        { key: "cpu", name: "CPU", width: 96 },
        { key: "mem", name: "Memory", width: 110 },
        { key: "gpu", name: "GPU", width: 90 },
        { key: "disk", name: "Disk", width: 104 },
    ]
    function headerValue(key) {
        const t = root.totals
        if (key === "cpu") return root.pct(t.cpu)
        if (key === "mem") return root.pct(t.mem)
        if (key === "gpu") return t.gpu === null || t.gpu === undefined ? "" : t.gpu + "%"
        if (key === "disk") return root.rate((t.diskRead ?? 0) + (t.diskWrite ?? 0))
        return ""
    }
    function cell(g, key) {
        if (key === "cpu") return root.pct(g.cpu)
        if (key === "mem") return root.bytes(g.mem)
        if (key === "gpu") return g.own ? g.gpu.toFixed(1) + "%" : "—"
        if (key === "disk") return g.own ? root.rate(g.disk) : "—"
        return ""
    }

    component ProcRow: Rectangle {
        id: row
        required property var g
        visible: g !== undefined && g !== null
        property bool first: false
        property bool last: false
        readonly property bool sel: root.selectedKey === g?.key
        Layout.fillWidth: true
        implicitHeight: 52
        topLeftRadius: first ? Appearance.rounding.large : 6
        topRightRadius: first ? Appearance.rounding.large : 6
        bottomLeftRadius: last ? Appearance.rounding.large : 6
        bottomRightRadius: last ? Appearance.rounding.large : 6
        color: sel ? Appearance.colors.colSecondaryContainer : rowMouse.containsMouse ? Appearance.colors.colLayer3Hover : Appearance.colors.colLayer3
        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.selectedKey = row.sel ? "" : row.g?.key
        }
        RowLayout {
            anchors { fill: parent; leftMargin: 16; rightMargin: 18 }
            spacing: 14
            Item {
                implicitWidth: 30
                implicitHeight: 30
                IconImage {
                    visible: row.g?.kind === "app"
                    anchors.fill: parent
                    source: row.g?.kind === "app" ? Quickshell.iconPath(AppSearch.guessIcon(row.g?.cls), "application-x-executable") : ""
                }
                Rectangle {
                    visible: row.g?.kind !== "app"
                    anchors.fill: parent
                    radius: 9
                    color: row.sel ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colSecondaryContainer
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: row.g?.kind === "system" ? "shield" : "memory"
                        iconSize: 17
                        color: Appearance.colors.colOnSecondaryContainer
                    }
                }
            }
            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: !row.g ? "" : root.label(row.g) + (row.g?.count > 1 ? `  <font color="${Appearance.colors.colSubtext}">${row.g?.count} processes</font>` : "")
                textFormat: Text.StyledText
                font.pixelSize: Appearance.font.pixelSize.small
                color: row.sel ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer3
            }
            Repeater {
                model: root.columns
                StyledText {
                    required property var modelData
                    Layout.preferredWidth: modelData.width
                    horizontalAlignment: Text.AlignRight
                    text: row.g ? root.cell(row.g, modelData.key) : ""
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.family: Appearance.font.family.numbers
                    color: row.sel ? Appearance.colors.colOnSecondaryContainer
                        : (modelData.key === "cpu" && row.g?.cpu > 25) || (modelData.key === "mem" && row.g?.mem > 2147483648) ? Appearance.colors.colTertiary
                        : Appearance.colors.colOnLayer3
                }
            }
        }
    }

    component SectionTitle: StyledText {
        Layout.topMargin: 10
        Layout.leftMargin: 6
        Layout.bottomMargin: 2
        font.pixelSize: Appearance.font.pixelSize.small
        font.weight: Font.Medium
        color: Appearance.colors.colSubtext
    }

    Component {
        id: processesPage
        ColumnLayout {
            spacing: 8
            RowLayout {   // column headers: click to sort
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 18 + 24
                spacing: 14
                Item { implicitWidth: 30 }
                Repeater {
                    model: [{ key: "name", name: "Name", width: -1 }].concat(root.columns)
                    MouseArea {
                        required property var modelData
                        Layout.fillWidth: modelData.width < 0
                        Layout.preferredWidth: modelData.width < 0 ? 100 : modelData.width
                        implicitHeight: 34
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.sortKey === modelData.key) root.sortDesc = !root.sortDesc
                            else { root.sortKey = modelData.key; root.sortDesc = modelData.key !== "name" }
                        }
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 0
                            StyledText {
                                Layout.fillWidth: true
                                horizontalAlignment: modelData.width < 0 ? Text.AlignLeft : Text.AlignRight
                                text: modelData.name + (root.sortKey === modelData.key ? (root.sortDesc ? " ↓" : " ↑") : "")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: root.sortKey === modelData.key ? Font.DemiBold : Font.Normal
                                color: Appearance.colors.colSubtext
                            }
                            StyledText {
                                Layout.fillWidth: true
                                visible: modelData.width > 0
                                horizontalAlignment: Text.AlignRight
                                text: root.headerValue(modelData.key)
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                    }
                }
            }
            WPage {
                Layout.fillWidth: true
                Layout.fillHeight: true
                maxContentWidth: 4000
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    SectionTitle { text: `Apps (${root.appProcs.length})` }
                    Repeater {
                        model: root.appProcs
                        ProcRow { required property var modelData; required property int index; g: modelData; first: index === 0; last: index === root.appProcs.length - 1 }
                    }
                    SectionTitle { text: `Background processes (${root.bgProcs.length})` }
                    Repeater {
                        model: root.bgProcs
                        ProcRow { required property var modelData; required property int index; g: modelData; first: index === 0; last: index === root.bgProcs.length - 1 }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        SectionTitle { text: `System processes (${root.sysProcs.length})` }
                        Item { Layout.fillWidth: true }
                        WButton {
                            Layout.topMargin: 8
                            buttonText: root.showSystem ? "Hide" : "Show"
                            onClicked: root.showSystem = !root.showSystem
                        }
                    }
                    Repeater {
                        model: root.showSystem ? root.sysProcs : []
                        ProcRow { required property var modelData; required property int index; g: modelData; first: index === 0; last: index === root.sysProcs.length - 1 }
                    }
                }
            }
            // details of the selected row, and the Force end offer
            Rectangle {
                Layout.fillWidth: true
                visible: root.selected !== null || root.forceOffer
                implicitHeight: 56
                radius: Appearance.rounding.large
                color: root.forceOffer ? Appearance.colors.colErrorContainer : Appearance.colors.colLayer2
                RowLayout {
                    anchors { fill: parent; leftMargin: 20; rightMargin: 10 }
                    spacing: 12
                    MaterialSymbol {
                        text: root.forceOffer ? "warning" : "info"
                        iconSize: 20
                        color: root.forceOffer ? Appearance.colors.colOnErrorContainer : Appearance.colors.colSubtext
                    }
                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: root.forceOffer ? Appearance.colors.colOnErrorContainer : Appearance.colors.colSubtext
                        text: root.forceOffer ? `${root.pending?.name ?? ""} didn't close. Force end closes it right away; unsaved work is lost.`
                            : root.selected ? `PID ${root.selected.pid} · ${root.selected.user} · ${root.selected.count} process${root.selected.count > 1 ? "es" : ""} · ${root.selected.cmd || root.selected.name}` : ""
                    }
                    WButton {
                        visible: root.forceOffer
                        buttonText: "Force end"
                        onClicked: root.forceEnd()
                    }
                }
            }
        }
    }

    // ── Performance ─────────────────────────────────────────────────────────────────────────────────────────────────
    property string perf: "cpu"
    readonly property var perfItems: [
        { id: "cpu", name: "CPU", hist: root.cpuHist,
          value: root.pct((root.stats.cpu?.usage ?? 0) * 100) + "  " + ((root.stats.cpu?.freqAvg ?? 0) / 1000).toFixed(2) + " GHz" },
        { id: "mem", name: "Memory", hist: root.memHist,
          value: root.bytes(root.totals.memUsed) + " / " + root.bytes(root.totals.memTotal) + "  (" + Math.round(root.totals.mem ?? 0) + "%)" },
        { id: "gpu", name: "GPU", hist: root.gpuHist,
          value: Math.round((root.stats.gpu?.busy ?? 0) * 100) + "%  " + ((root.stats.gpu?.temp ?? 0) ? Math.round(root.stats.gpu.temp) + " °C" : "") },
        { id: "disk", name: "Disk", hist: root.diskHist,
          value: "R " + root.rate(root.totals.diskRead) + "  W " + root.rate(root.totals.diskWrite) },
        { id: "net", name: "Network", hist: root.netHist,
          value: "↓ " + root.rate(root.stats.net?.rx) + "  ↑ " + root.rate(root.stats.net?.tx) },
    ]
    function details(id) {
        const s = root.stats, t = root.totals
        if (id === "cpu") return [
            ["Processor", s.cpu?.model ?? "—"], ["Usage", root.pct((s.cpu?.usage ?? 0) * 100)],
            ["Speed", ((s.cpu?.freqAvg ?? 0) / 1000).toFixed(2) + " GHz (max " + ((s.cpu?.freqMax ?? 0) / 1000).toFixed(2) + ")"],
            ["Cores / threads", (s.cpu?.cores ?? "—") + " / " + (s.cpu?.threads ?? "—")],
            ["Temperature", s.cpu?.temp ? Math.round(s.cpu.temp) + " °C" : "—"], ["Power", s.cpu?.power ? Math.round(s.cpu.power) + " W" : (s.cpu?.powerNote || "—")],
            ["Processes", String(t.procs ?? "—")], ["Threads", String(t.threads ?? "—")],
            ["Load (1 / 5 / 15 min)", (s.cpu?.load ?? []).join(" / ")], ["Up time", root.duration(s.sys?.uptime)]]
        if (id === "mem") return [
            ["In use", root.bytes(t.memUsed)], ["Total", root.bytes(t.memTotal)],
            ["Available", root.bytes(s.mem?.available)], ["Cached", root.bytes(s.mem?.cached)],
            ["Swap in use", root.bytes(s.mem?.swapUsed) + " of " + root.bytes(s.mem?.swapTotal)],
            ["Compressed (zram)", s.mem?.zram ? root.bytes(s.mem.zram.compr) + " for " + root.bytes(s.mem.zram.orig) : "—"]]
        if (id === "gpu") return [
            ["Graphics card", s.gpu?.name ?? "—"], ["Usage", Math.round((s.gpu?.busy ?? 0) * 100) + "%"],
            ["Video memory", root.bytes(s.gpu?.vramUsed) + " of " + root.bytes(s.gpu?.vramTotal)],
            ["Temperature", s.gpu?.temp ? Math.round(s.gpu.temp) + " °C" : "—"],
            ["Power", s.gpu?.power ? Math.round(s.gpu.power) + " W of " + Math.round(s.gpu.powerCap ?? 0) + " W" : "—"],
            ["Clock", s.gpu?.sclk ? Math.round(s.gpu.sclk) + " MHz (memory " + Math.round(s.gpu.mclk ?? 0) + " MHz)" : "—"]]
        if (id === "disk") return [
            ["Reading", root.rate(t.diskRead)], ["Writing", root.rate(t.diskWrite)], ["Busy", root.pct(t.diskBusy)]]
            .concat((s.disks ?? []).map(d => ["Space on " + d.path, root.bytes(d.used) + " of " + root.bytes(d.total)]))
            .concat((s.nvme ?? []).map(n => [n.model, Math.round(n.temp) + " °C"]))
        if (id === "net") return [["Receiving", root.rate(s.net?.rx)], ["Sending", root.rate(s.net?.tx)]]
        return []
    }

    Component {
        id: performancePage
        RowLayout {
            spacing: 16
            ColumnLayout {   // metric list
                Layout.preferredWidth: 300
                Layout.maximumWidth: 300
                Layout.fillHeight: true
                spacing: 4
                Repeater {
                    model: root.perfItems
                    RippleButton {
                        id: metric
                        required property var modelData
                        required property int index
                        readonly property bool cur: root.perf === modelData.id
                        Layout.fillWidth: true
                        implicitHeight: 96
                        buttonRadius: index === 0 ? Appearance.rounding.large : (index === root.perfItems.length - 1 ? Appearance.rounding.large : 6)
                        colBackground: cur ? Appearance.colors.colSecondaryContainer : Appearance.colors.colLayer3
                        colBackgroundHover: cur ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colLayer3Hover
                        onClicked: root.perf = modelData.id
                        contentItem: ColumnLayout {
                            spacing: 2
                            StyledText {
                                Layout.leftMargin: 16
                                text: metric.modelData.name
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: metric.cur ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer3
                            }
                            StyledText {
                                Layout.leftMargin: 16
                                text: metric.modelData.value
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: metric.cur ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colSubtext
                            }
                            Graph {
                                Layout.fillWidth: true
                                Layout.leftMargin: 16
                                Layout.rightMargin: 16
                                implicitHeight: 30
                                values: metric.modelData.hist
                                points: root.histLen
                                alignment: Graph.Alignment.Right
                                fillOpacity: 0.25
                                color: metric.cur ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colPrimary
                            }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
            }
            ColumnLayout {   // details
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 14
                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: root.perfItems.find(p => p.id === root.perf)?.name ?? ""
                        font.family: Appearance.font.family.expressive
                        font.pixelSize: Appearance.font.pixelSize.huge
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer1
                    }
                    Item { Layout.fillWidth: true }
                    StyledText {
                        text: root.perf === "net" || root.perf === "disk" ? "last 90 seconds, auto scale" : "last 90 seconds, 0–100%"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 240
                    radius: Appearance.rounding.large
                    color: Appearance.colors.colLayer2
                    clip: true
                    Graph {
                        anchors.fill: parent
                        anchors.topMargin: 16
                        values: root.perfItems.find(p => p.id === root.perf)?.hist ?? []
                        points: root.histLen
                        alignment: Graph.Alignment.Right
                        fillOpacity: 0.3
                        color: Appearance.colors.colPrimary
                    }
                }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 12
                    rowSpacing: 4
                    Repeater {
                        model: root.details(root.perf)
                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredWidth: 100
                            implicitHeight: 52
                            radius: 14
                            color: Appearance.colors.colLayer3
                            ColumnLayout {
                                anchors { fill: parent; leftMargin: 16; rightMargin: 12 }
                                spacing: 0
                                StyledText {
                                    Layout.fillWidth: true
                                    text: modelData[0]
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                    elide: Text.ElideRight
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: modelData[1]
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colOnLayer3
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }
    }

    // ── Startup ─────────────────────────────────────────────────────────────────────────────────────────────────────
    function openSettings(page, sub) { Quickshell.execDetached(["qs", "-c", "end4-pC", "ipc", "call", "settings", "go", page, sub]) }
    Component {
        id: startupPage
        // One list, a switch each, like Windows (2026-10-16): services/StartupItems.qml (shared with Settings)
        WPage {
            id: sp
            maxContentWidth: 4000
            Component.onCompleted: StartupItems.refresh()
            readonly property int onCount: StartupItems.items.filter(i => i.on).length
            WSection {
                title: `Apps that start when you sign in · ${sp.onCount} on, ${StartupItems.items.length - sp.onCount} off`
                Repeater {
                    model: StartupItems.items
                    WToggle {
                        id: row
                        required property var modelData
                        minHeight: 58
                        title: modelData.name
                        description: modelData.source
                        showStateText: true
                        checked: modelData.on
                        onToggled: v => modelData.set(v)
                        icon: modelData.symbol
                        leading: modelData.symbol ? null : appIcon
                        Component { id: appIcon; IconImage { implicitSize: 28; source: Quickshell.iconPath(row.modelData.icon, "application-x-executable") } }
                    }
                }
                WCard {
                    visible: StartupItems.items.length === 0
                    icon: "inbox"
                    title: "Nothing starts when you sign in"
                }
                WLink {
                    icon: "add_circle"
                    title: "Add a startup app"
                    description: "Settings › Apps › Startup"
                    chevronIcon: "open_in_new"
                    action: () => root.openSettings("apps", "startup")
                }
            }
            WSection {
                visible: StartupItems.scriptExists
                title: "Your own startup script (runs after you unlock)"
                WCard {
                    icon: "description"
                    title: StartupItems.scriptPrograms.length > 0 ? StartupItems.scriptPrograms.join(", ") : "Nothing"
                    description: "Commands in ~/.config/hypr/custom/scripts/autostart-user.sh. Edit the script to change them"
                    WButton { buttonText: "Edit script"; onClicked: Quickshell.execDetached([`${Quickshell.env("HOME")}/.local/bin/phoenix-open`, "editor", StartupItems.scriptPath]) }
                }
            }
        }
    }

    // ── Services ────────────────────────────────────────────────────────────────────────────────────────────────────
    Component {
        id: servicesPage
        ColumnLayout {
            id: svc
            spacing: 12
            property var units: []      // {unit, description, active, sub, load, scope}
            property string filter: "running"
            property string query: ""
            function refresh() { listProc.running = true }
            Process {
                id: listProc
                running: true
                command: ["bash", "-c", "systemctl list-units --type=service --all --no-pager -o json 2>/dev/null; echo; systemctl --user list-units --type=service --all --no-pager -o json 2>/dev/null"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const parts = text.split("\n").filter(l => l.trim().startsWith("["))
                        let all = []
                        parts.forEach((p, i) => {
                            try { all = all.concat(JSON.parse(p).map(u => Object.assign(u, { scope: i === 0 ? "system" : "user" }))) } catch (e) {}
                        })
                        svc.units = all.filter(u => u.load !== "not-found")
                    }
                }
            }
            Timer { interval: 5000; running: true; repeat: true; onTriggered: svc.refresh() }
            // stopping these breaks the session or the system (D-Bus, logins, the session manager itself)
            function essential(u) { return /^(dbus|dbus-broker|systemd-|user@|user-runtime-dir@|getty@|greetd|display-manager|polkit|at-spi-dbus-bus|xdg-desktop-portal)/.test(u.unit) }
            function act(u, verb) {
                const cmd = u.scope === "user" ? ["systemctl", "--user", verb, u.unit] : ["pkexec", "systemctl", verb, u.unit]
                Quickshell.execDetached(["bash", "-c", cmd.map(c => `'${c}'`).join(" ") + "; sleep 0.5"])
                refreshSoon.restart()
            }
            Timer { id: refreshSoon; interval: 1500; onTriggered: svc.refresh() }
            readonly property var shown: svc.units.filter(u =>
                (svc.filter === "all" || (svc.filter === "running" && u.sub === "running") || (svc.filter === "failed" && u.active === "failed"))
                && (svc.query === "" || (u.unit + " " + u.description).toLowerCase().includes(svc.query.toLowerCase())))
                .sort((a, b) => (a.scope === b.scope ? 0 : a.scope === "user" ? -1 : 1) || a.unit.localeCompare(b.unit))

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: [{ id: "running", name: "Running" }, { id: "failed", name: "Failed" }, { id: "all", name: "All" }]
                    RippleButton {
                        required property var modelData
                        readonly property bool cur: svc.filter === modelData.id
                        implicitHeight: 40
                        implicitWidth: chip.implicitWidth + 36
                        buttonRadius: 20
                        colBackground: cur ? Appearance.colors.colSecondaryContainer : "transparent"
                        colBackgroundHover: cur ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colLayer1Hover
                        border: !cur
                        onClicked: svc.filter = modelData.id
                        contentItem: Item {
                            StyledText {
                                id: chip
                                anchors.centerIn: parent
                                text: modelData.name + (modelData.id === "failed" ? ` (${svc.units.filter(u => u.active === "failed").length})` : "")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: cur ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                            }
                        }
                    }
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    implicitWidth: 260
                    implicitHeight: 40
                    radius: 20
                    color: Appearance.colors.colLayer2
                    RowLayout {
                        anchors { fill: parent; leftMargin: 16; rightMargin: 14 }
                        spacing: 8
                        MaterialSymbol { text: "search"; iconSize: 18; color: Appearance.colors.colSubtext }
                        TextField {
                            Layout.fillWidth: true
                            placeholderText: "Search services"
                            placeholderTextColor: Appearance.colors.colSubtext
                            color: Appearance.colors.colOnLayer1
                            font.family: Appearance.font.family.main
                            font.pixelSize: Appearance.font.pixelSize.small
                            background: null
                            onTextChanged: svc.query = text
                        }
                    }
                }
            }
            StyledText {
                Layout.leftMargin: 6
                text: `${svc.shown.length} services · yours first; starting or stopping a system service asks for your password`
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 4
                boundsBehavior: Flickable.StopAtBounds
                model: svc.shown
                ScrollBar.vertical: StyledScrollBar {}
                delegate: WCard {
                    id: unitCard
                    required property var modelData
                    width: ListView.view.width - 12
                    grouped: false
                    icon: modelData.scope === "user" ? "person" : "dns"
                    title: modelData.unit.replace(/\.service$/, "")
                    description: modelData.description + (modelData.scope === "user" ? " · yours" : " · system")
                    Rectangle {
                        implicitHeight: 28
                        implicitWidth: stateText.implicitWidth + 22
                        radius: 14
                        color: unitCard.modelData.active === "failed" ? Appearance.colors.colErrorContainer
                            : unitCard.modelData.sub === "running" ? Appearance.colors.colSecondaryContainer : Appearance.colors.colLayer4
                        StyledText {
                            id: stateText
                            anchors.centerIn: parent
                            text: unitCard.modelData.active === "failed" ? "Failed" : unitCard.modelData.sub === "running" ? "Running"
                                : unitCard.modelData.sub === "exited" ? "Done" : unitCard.modelData.sub === "dead" ? "Stopped" : unitCard.modelData.sub
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: unitCard.modelData.active === "failed" ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnSecondaryContainer
                        }
                    }
                    StyledText {
                        visible: svc.essential(unitCard.modelData)
                        text: "Needed by the system"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                    WButton {
                        visible: !svc.essential(unitCard.modelData)
                        buttonText: unitCard.modelData.sub === "running" ? "Stop" : "Start"
                        onClicked: svc.act(unitCard.modelData, unitCard.modelData.sub === "running" ? "stop" : "start")
                    }
                    WButton {
                        visible: unitCard.modelData.sub === "running" && !svc.essential(unitCard.modelData)
                        buttonText: "Restart"
                        onClicked: svc.act(unitCard.modelData, "restart")
                    }
                }
            }
        }
    }

    // ── Users ───────────────────────────────────────────────────────────────────────────────────────────────────────
    Component {
        id: usersPage
        WPage {
            id: up
            maxContentWidth: 4000
            property var sessions: []
            Process {
                running: true
                // loginctl's table (its -o json is ignored by list-sessions): SESSION UID USER SEAT LEADER CLASS TTY IDLE SINCE
                command: ["loginctl", "list-sessions", "--no-legend"]
                stdout: StdioCollector {
                    onStreamFinished: up.sessions = text.split("\n").map(l => l.trim().split(/\s+/)).filter(c => c.length >= 7 && c[5] !== "manager")
                        .map(c => ({ session: c[0], user: c[2], seat: c[3] === "-" ? "" : c[3], class: c[5], tty: c[6] === "-" ? "" : c[6], state: c[7] === "yes" ? "idle" : "active" }))
                }
            }
            readonly property var perUser: {
                const m = {}
                root.groups.forEach(g => {
                    const u = m[g.user] ?? (m[g.user] = { user: g.user, cpu: 0, mem: 0, count: 0 })
                    u.cpu += g.cpu; u.mem += g.mem; u.count += g.count
                })
                return Object.values(m).sort((a, b) => b.mem - a.mem)
            }
            WSection {
                title: "Signed in"
                Repeater {
                    model: up.sessions
                    WCard {
                        required property var modelData
                        icon: "account_circle"
                        title: modelData.user
                        description: `Session ${modelData.session}` + (modelData.seat ? ` · ${modelData.seat}` : "") + (modelData.tty ? ` · ${modelData.tty}` : "")
                            + (modelData.class ? ` · ${modelData.class}` : "") + (modelData.state ? ` · ${modelData.state}` : "")
                    }
                }
            }
            WSection {
                title: "What each account is using"
                Repeater {
                    model: up.perUser
                    WCard {
                        required property var modelData
                        icon: modelData.user === "root" ? "shield" : "person"
                        title: modelData.user === "root" ? "root (the system)" : modelData.user
                        description: `${modelData.count} process${modelData.count === 1 ? "" : "es"}`
                        StyledText {
                            text: `CPU ${root.pct(modelData.cpu)}`
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer3
                        }
                        StyledText {
                            Layout.leftMargin: 18
                            text: `Memory ${root.bytes(modelData.mem)}`
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer3
                        }
                    }
                }
            }
        }
    }
}
