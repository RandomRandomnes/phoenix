import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Extras (2026-10-03, ours): every custom feature of this setup with an on/off switch. Off falls back to the stock
// illogical-impulse behaviour. The switches are Config.options.extras (+ a few sidebar ones); services/Extras.qml
// applies the Hyprland side through ~/.local/bin/setup-features. Setup profiles set the same switches.
WPage {
    id: page
    readonly property var ex: Config.options.extras

    component Switch: WToggle {
        required property string key
        property var group: Config.options.extras
        checked: group[key]
        onToggled: v => group[key] = v
    }

    // ── Setup profiles (~/.local/bin/setup-profile) ──
    property string confirmId: ""       // profile waiting for a second click
    property string status: ""
    property string importPath: ""
    property var importApps: []         // apps the applied profile file lists (offered for install)

    function runProfile(args, doneText) {
        page.status = "Working…"
        profileProc.doneText = doneText
        profileProc.command = [`${Quickshell.env("HOME")}/.local/bin/setup-profile`].concat(args)
        profileProc.running = true
    }
    function askApply(id) {
        if (page.confirmId === id) {
            page.confirmId = ""
            page.runProfile(["apply", id, "--yes"], "Profile applied; old settings backed up")
        } else {
            page.confirmId = id
            confirmTimer.restart()
        }
    }

    Timer { id: confirmTimer; interval: 4000; onTriggered: page.confirmId = "" }
    Process {
        id: profileProc
        property string doneText: ""
        stderr: StdioCollector { id: profileErr }
        onExited: (code, status) => {
            page.status = code === 0 ? doneText : `Something went wrong: ${profileErr.text.trim()}`
            if (code === 0 && command[1] === "apply") { appsOfProfile.command = [command[0], "apps", command[2]]; appsOfProfile.running = true }
        }
    }
    Process {
        id: appsOfProfile
        stdout: StdioCollector { onStreamFinished: page.importApps = text.split("\n").filter(l => l.trim() !== "") }
    }
    Process {
        id: importPicker
        command: [`${Quickshell.env("HOME")}/.local/bin/phoenix-file-picker`, "open", Quickshell.env("HOME"), "Setup profiles", "*.json"]
        stdout: StdioCollector { onStreamFinished: if (text.trim() !== "") page.importPath = text.trim() }
    }
    Process {
        id: exportPicker
        command: [`${Quickshell.env("HOME")}/.local/bin/phoenix-file-picker`, "save", `${Quickshell.env("HOME")}/my-setup.json`, "Setup profiles", "*.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                let f = text.trim()
                if (f === "") return
                if (!f.endsWith(".json")) f += ".json"
                page.runProfile(["export", f, "--name", `${SystemInfo.username}'s setup`], `Saved to ${f}`)
            }
        }
    }

    WSection {
        title: "Setup profiles"
        WCard {
            icon: "menu_book"
            title: "Quick Start"
            keywords: "guide"
            description: "Shortcuts, windows, updates, troubleshooting"
            WButton {
                buttonText: "Open"
                onClicked: Quickshell.execDetached([`${Quickshell.env("HOME")}/.local/bin/phoenix-open`, "quickstart"])
            }
        }
        WCard {
            icon: "assistant"
            title: "Run the first-time setup again"
            keywords: "assistant"
            description: "Network, Bluetooth, profile, apps, updates"
            WButton {
                buttonText: "Open"
                onClicked: Quickshell.execDetached(["bash", "-c", `mkdir -p ~/.local/state/setup-wizard && touch ~/.local/state/setup-wizard/pending && qs -p ${Quickshell.shellPath("setup-wizard.qml")}`])
            }
        }
        WCard {
            icon: "upload_file"
            title: page.importPath === "" ? "Use a profile file" : page.importPath.split("/").pop()
            description: page.importPath === "" ? "A setup profile (.json)" : page.importPath
            WButton {
                buttonText: "Choose file…"
                onClicked: importPicker.running = true
            }
            WButton {
                visible: page.importPath !== ""
                buttonText: page.confirmId === page.importPath ? "Click again to apply" : "Apply"
                accent: page.confirmId === page.importPath
                onClicked: page.askApply(page.importPath)
            }
        }
        WCard {
            icon: "ios_share"
            title: "Share my setup"
            keywords: "save export"
            description: "Saves your setup as a profile file"
            WButton {
                buttonText: "Save as file…"
                onClicked: exportPicker.running = true
            }
        }
        WCard {
            visible: page.status !== ""
            icon: "check_circle"
            title: page.status
        }
        WCard {
            visible: page.importApps.length > 0
            icon: "download"
            title: "This profile includes applications"
            description: page.importApps.join(", ") + ". Installed ones are skipped"
            WButton {
                accent: true
                buttonText: Tasks.isRunning("apps") ? "Installing…" : "Install"
                enabled: !Tasks.isRunning("apps")
                // a background job with its progress below (2026-10-16; was a terminal window)
                onClicked: Tasks.run("apps", [`${Quickshell.env("HOME")}/.local/bin/setup-apps`, "install", ...page.importApps],
                    { title: "Installing apps", askpassMessage: "Enter your password to install the apps" })
            }
        }
        WJob { jobId: "apps" }
    }

    WSection {
        title: "Windows"
        Switch {
            key: "windowsStyle"
            icon: "select_window"
            title: "Windows-style windows"
            description: "Floating windows with title bars. Off: tiling"
        }
        Switch {
            key: "minimizeToDock"
            icon: "minimize"
            title: "Minimize to the dock"
            description: "Click the app in the dock to restore"
        }
        Switch {
            key: "workspaceGroups"
            icon: "view_carousel"
            title: "Own workspaces for each screen"
            description: "Screen 1: 1-10, screen 2: 11-20, and so on"
        }
    }

    WSection {
        title: "Desktop"
        Switch {
            key: "wallpaperEngine"
            icon: "animated_images"
            title: "Wallpaper Engine background"
            description: "Needs Wallpaper Engine from Steam"
        }
        Switch {
            key: "appGrid"
            icon: "apps"
            title: "App grid in the Super menu"
            description: "Apps below the workspaces when you press Super"
        }
        WLink {
            visible: page.ex.appGrid
            icon: "grid_view"
            title: "Choose the applications in the grid"
            page: "personalization"; sub: "appgrid"
        }
    }

    WSection {
        title: "Taskbar and menus"
        Switch {
            key: "resourceGraphs"
            icon: "monitoring"
            title: "Live system graphs on the taskbar"
            description: "CPU, GPU and memory graphs. Off: round gauges"
        }
        Switch {
            key: "powerMenuKde"
            icon: "swap_horiz"
            title: "\"Switch to KDE\" in the power menu"
            description: "Replaces Hibernate"
        }
        Switch {
            key: "updatesScript"
            icon: "deployed_code_update"
            title: "One-click full update"
            description: "Off: plain system update only"
        }
    }

    WSection {
        title: "Right sidebar"
        Switch {
            key: "wallpaperEngineCard"; group: Config.options.sidebar
            visible: page.ex.wallpaperEngine
            icon: "wallpaper"
            title: "Wallpaper Engine picker"
            description: "Pick, shuffle and mute live wallpapers"
        }
        Switch {
            key: "deviceBatteries"; group: Config.options.sidebar
            icon: "battery_full"
            title: "Device batteries"
            description: "Mouse, headset and controller batteries"
        }
        Switch {
            key: "desktopSwitch"; group: Config.options.sidebar
            icon: "swap_horiz"
            title: "Switch to KDE Plasma button"
            description: "Header button that switches to KDE Plasma"
        }
    }

    WSection {
        title: "Applications"
        Switch {
            key: "claudeCodeAi"
            icon: "smart_toy"
            title: "Claude Code in the AI sidebar"
            description: "In the left sidebar. Needs Claude Code and a subscription"
        }
        Switch {
            key: "steamTray"
            icon: "sports_esports"
            title: "Start Steam at login"
            description: "Starts in the tray after sign-in"
        }
    }

    // Phoenix (2026-10-15): settings moved here from illogical-impulse's original settings
    SServices {}
    SOverlay {}
}
