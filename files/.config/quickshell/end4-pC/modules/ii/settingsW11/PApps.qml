import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    Loader {
        anchors.fill: parent
        sourceComponent: ({ "installed": installed, "defaults": defaults, "startup": startup, "rules": rules, "autostart": autostartPage
        })[WState.sub] ?? overview
    }

    readonly property string helper: Quickshell.shellPath("modules/ii/settingsW11/defaultapps.py")

    component AppIconImage: IconImage {
        property string iconName
        implicitSize: 28
        source: Quickshell.iconPath(iconName, "application-x-executable")
    }

    // ── Overview ───────────────────────────────────────────────────
    Component {
        id: overview
        WPage {
            WSection {
                WLink { icon: "apps"; title: "Installed apps"; description: "Uninstall and open apps"; sub: "installed" }
                WLink { icon: "app_registration"; title: "Default apps"; description: "Defaults for files and links: browser, file manager, media"; sub: "defaults" }
                WLink { icon: "rocket_launch"; title: "Startup"; description: "Apps that start automatically when you sign in"; sub: "startup" }
                WLink { icon: "select_window"; title: "Window rules"; description: "How an app's windows open: floating, size, position, workspace, opacity"; sub: "rules" }
            }
            WSection {
                title: "Related"
                WLink { icon: "storefront"; title: "Get more apps"; description: "Opens Discover if installed, otherwise the Arch package search"; chevronIcon: "open_in_new"; action: () => Quickshell.execDetached(["bash", "-c", "command -v plasma-discover >/dev/null && plasma-discover || xdg-open https://archlinux.org/packages/"]) }
                WLink { icon: "terminal"; title: "Default terminal"; description: Config.options.apps.terminal; sub: "defaults" }
            }
        }
    }

    // ── Window rules (WWindowRules.qml) ────────────────────────────
    Component {
        id: rules
        WWindowRules {}
    }

    // ── Installed apps ─────────────────────────────────────────────
    Component {
        id: installed
        WPage {
            id: ip
            property string query: ""
            property string sortMode: "name"
            readonly property var apps: {
                const q = ip.query.trim().toLowerCase();
                const l = AppSearch.list.filter(e => !e.noDisplay && (q === "" || e.name.toLowerCase().includes(q) || (e.genericName ?? "").toLowerCase().includes(q)));
                return l.sort((a, b) => a.name.localeCompare(b.name));
            }
            function uninstall(entry) { AppSearch.uninstall(entry) }   // shared with the Super menu's right-click menu

            WCard {
                icon: "search"
                title: `${ip.apps.length} apps`
                Rectangle {
                    implicitWidth: 300; implicitHeight: 36
                    radius: 12
                    color: Appearance.colors.colLayer4
                    border.width: appSearch.activeFocus ? 2 : 0
                    border.color: Appearance.colors.colPrimary
                    TextField {
                        id: appSearch
                        anchors.fill: parent
                        leftPadding: 10
                        background: null
                        placeholderText: "Search apps"
                        placeholderTextColor: Appearance.colors.colSubtext
                        color: Appearance.colors.colOnLayer3
                        font.family: Appearance.font.family.main
                        font.pixelSize: Appearance.font.pixelSize.small
                        onTextChanged: ip.query = text
                    }
                }
            }

            WSection {
                Repeater {
                    model: ip.apps
                    WCard {
                        id: appRow
                        required property var modelData
                        minHeight: 58
                        title: modelData.name
                        description: modelData.genericName || modelData.comment || ""
                        leading: Component { AppIconImage { iconName: appRow.modelData.icon } }
                        WButton { buttonText: "Open"; onClicked: { appRow.modelData.execute(); GlobalStates.settingsOpen = false; } }
                        WButton { buttonText: "Uninstall"; onClicked: ip.uninstall(appRow.modelData) }
                    }
                }
            }
        }
    }

    // ── Default apps ───────────────────────────────────────────────
    Component {
        id: defaults
        WPage {
            id: dp
            property var data: ({})
            Component.onCompleted: listProc.running = true
            Connections { target: WState; function onRefreshTickChanged() { listProc.running = true } }   // e.g. a browser installed meanwhile
            Process {
                id: listProc
                command: ["python3", root.helper, "list"]
                stdout: StdioCollector { onStreamFinished: { try { dp.data = JSON.parse(text) } catch (e) {} } }
            }
            Process {
                id: setProc
                onExited: listProc.running = true
            }
            function setDefault(cat, id) {
                setProc.command = ["python3", root.helper, "set", cat, id];
                setProc.running = true;
            }
            function model(cat) {
                const d = dp.data[cat];
                if (!d) return [];
                const m = d.candidates.map(c => ({ displayName: c.name, value: c.id }));
                if (d.current && !m.some(x => x.value === d.current))
                    m.unshift({ displayName: `${d.current.replace(/\.desktop$/, "")} (current)`, value: d.current });
                if (!d.current) m.unshift({ displayName: "Not set", value: "" });
                return m;
            }

            WSection {
                title: "Set defaults for applications"
                Repeater {
                    model: [
                        ["browser", "Web browser", "language"],
                        ["files", "File manager", "folder"],
                        ["text", "Text editor", "description"],
                        ["image", "Photo viewer", "image"],
                        ["video", "Video player", "movie"],
                        ["music", "Music player", "music_note"],
                        ["pdf", "PDF reader", "picture_as_pdf"],
                        ["mail", "Email", "mail"],
                        ["archive", "Archive manager", "folder_zip"],
                    ]
                    WCombo {
                        required property var modelData
                        icon: modelData[2]
                        title: modelData[1]
                        fieldWidth: 300
                        model: dp.model(modelData[0])
                        currentValue: dp.data[modelData[0]]?.current ?? ""
                        onSelected: v => { if (v) dp.setDefault(modelData[0], v) }
                    }
                }
            }

            WSection {
                title: "Shell"
                WCombo {
                    icon: "terminal"
                    title: "Terminal"
                    description: "Used by the shell and keyboard shortcuts"
                    model: [
                        { displayName: "kitty", value: "kitty -1" },
                        { displayName: "Konsole", value: "konsole" },
                        { displayName: "Alacritty", value: "alacritty" },
                        { displayName: "foot", value: "foot" },
                        { displayName: "WezTerm", value: "wezterm" },
                    ].concat(["kitty -1", "konsole", "alacritty", "foot", "wezterm"].includes(Config.options.apps.terminal) ? [] : [{ displayName: Config.options.apps.terminal, value: Config.options.apps.terminal }])
                    currentValue: Config.options.apps.terminal
                    onSelected: v => Config.options.apps.terminal = v
                }
                WCombo {
                    icon: "monitoring"
                    title: "Task manager"
                    model: [
                        { displayName: "Task Manager (Phoenix)", value: "phoenix-task-manager" },
                        { displayName: "System Monitor (KDE)", value: "plasma-systemmonitor --page-name Processes" },
                        { displayName: "btop (in terminal)", value: "kitty -1 btop" },
                        { displayName: "htop (in terminal)", value: "kitty -1 htop" },
                        { displayName: "Mission Center", value: "missioncenter" },
                    ]
                    currentValue: Config.options.apps.taskManager
                    onSelected: v => Config.options.apps.taskManager = v
                }
            }
        }
    }

    // ── Startup ────────────────────────────────────────────────────
    // One list with a switch each (2026-10-16), the same as the Task Manager's Startup page: services/StartupItems.qml
    Component {
        id: startup
        WPage {
            id: sp
            Component.onCompleted: StartupItems.refresh()
            Connections { target: WState; function onRefreshTickChanged() { StartupItems.refresh() } }

            WSection {
                title: "Apps that start when you sign in"
                Repeater {
                    model: StartupItems.items
                    WToggle {
                        id: su
                        required property var modelData
                        minHeight: 58
                        title: modelData.name
                        description: modelData.source
                        showStateText: true
                        checked: modelData.on
                        onToggled: v => modelData.set(v)
                        icon: modelData.symbol
                        leading: modelData.symbol ? null : suIcon
                        Component { id: suIcon; AppIconImage { iconName: su.modelData.icon } }
                        // your own startup apps can also be taken off the list
                        WButton {
                            visible: su.modelData.key.startsWith("user:")
                            buttonText: "Remove"
                            onClicked: Config.options.hyprland.autostartApps.apps = StartupItems.userApps.filter(a => "user:" + a.cmd !== su.modelData.key)
                        }
                    }
                }
                WCard {
                    visible: StartupItems.items.length === 0
                    icon: "inbox"
                    title: "Nothing starts when you sign in"
                }
                WCard {
                    icon: "add_circle"
                    title: "Add a startup app"
                    Rectangle {
                        implicitWidth: 280; implicitHeight: 36
                        radius: 12
                        color: Appearance.colors.colLayer4
                        border.width: addSearch.activeFocus ? 2 : 0
                        border.color: Appearance.colors.colPrimary
                        TextField {
                            id: addSearch
                            anchors.fill: parent
                            leftPadding: 10
                            background: null
                            placeholderText: "Type an app name"
                            placeholderTextColor: Appearance.colors.colSubtext
                            color: Appearance.colors.colOnLayer3
                            font.family: Appearance.font.family.main
                            font.pixelSize: Appearance.font.pixelSize.small
                        }
                    }
                }
                Repeater {
                    model: addSearch.text.trim().length === 0 ? [] : AppSearch.fuzzyQuery(addSearch.text).filter(e => !e.noDisplay).slice(0, 6)
                    WCard {
                        id: cand
                        required property var modelData
                        Layout.leftMargin: 28
                        minHeight: 52
                        clickable: true
                        title: modelData.name
                        leading: Component { AppIconImage { iconName: cand.modelData.icon; implicitSize: 24 } }
                        onClicked: {
                            StartupItems.addUserApp(`gtk-launch ${modelData.id}`);
                            addSearch.text = "";
                        }
                        MaterialSymbol { text: "add"; iconSize: 20; color: Appearance.colors.colPrimary }
                    }
                }
            }

            WSection {
                title: "Your startup script"
                visible: StartupItems.scriptExists
                WCard {
                    icon: "description"
                    title: StartupItems.scriptPrograms.length > 0 ? StartupItems.scriptPrograms.join(", ") : "Nothing"
                    description: "Runs after you unlock: ~/.config/hypr/custom/scripts/autostart-user.sh"
                    WButton { buttonText: "Edit script"; onClicked: Quickshell.execDetached([`${Quickshell.env("HOME")}/.local/bin/phoenix-open`, "editor", StartupItems.scriptPath]) }
                }
            }
            WSection {
                title: "More"
                WLink { icon: "tune"; title: "Startup apps in detail"; description: "Edit each command, its workspace and the wait after it"; sub: "autostart" }
            }
        }
    }

    // Phoenix (2026-10-15): settings moved here from illogical-impulse's original settings
    Component {
        id: autostartPage
        WPage {
            SAutostart {}
        }
    }
}
