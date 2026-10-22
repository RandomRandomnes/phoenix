import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Extras (2026-10-03, ours): setup profiles, and a list of Phoenix's features. Their on/off switches
// (Config.options.extras + a few sidebar ones) moved to the pages they affect on 2026-10-22; services/Extras.qml
// still applies the Hyprland side through ~/.local/bin/setup-features. Setup profiles set the same switches.
WPage {
    id: page
    readonly property var ex: Config.options.extras

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

    // Phoenix's features (2026-10-22): each switch now lives on the page of what it changes; this list says what's
    // on and opens that page
    WSection {
        title: "Phoenix features"
        WLink { icon: "select_window"; title: "Windows-style windows"; description: (Config.options.extras.windowsStyle ? "On" : "Off") + " · System › Multitasking"; page: "system"; sub: "multitasking"; keywords: "title bars floating" }
        WLink { icon: "minimize"; title: "Minimize to the dock"; description: (Config.options.extras.minimizeToDock ? "On" : "Off") + " · System › Multitasking"; page: "system"; sub: "multitasking" }
        WLink { icon: "view_carousel"; title: "Own workspaces for each screen"; description: (Config.options.extras.workspaceGroups ? "On" : "Off") + " · System › Multitasking"; page: "system"; sub: "multitasking" }
        WLink { icon: "animated_images"; title: "Wallpaper Engine background"; description: (Config.options.extras.wallpaperEngine ? "On" : "Off") + " · Personalization › Background"; page: "personalization"; sub: "background" }
        WLink { icon: "grid_view"; title: "App grid in the Super menu"; description: (Config.options.extras.appGrid ? "On" : "Off") + " · Personalization › Super menu apps"; page: "personalization"; sub: "appgrid" }
        WLink { icon: "monitoring"; title: "Live system graphs"; description: (Config.options.extras.resourceGraphs ? "On" : "Off") + " · Personalization › Taskbar"; page: "personalization"; sub: "taskbar" }
        WLink { icon: "swap_horiz"; title: "Switch to KDE"; description: (Config.options.extras.powerMenuKde ? "On" : "Off") + " in the power menu · System › Power"; page: "system"; sub: "power" }
        WLink { icon: "right_panel_open"; title: "Sidebar extras"; description: "Wallpaper Engine picker, device batteries, KDE button · Personalization › Sidebar"; page: "personalization"; sub: "sidebar" }
        WLink { icon: "smart_toy"; title: "Claude Code in the AI sidebar"; description: (Config.options.extras.claudeCodeAi ? "On" : "Off") + " · Personalization › Sidebar"; page: "personalization"; sub: "sidebar" }
        WLink { icon: "deployed_code_update"; title: "One-click full update"; description: (Config.options.extras.updatesScript ? "On" : "Off") + " · Update"; page: "update" }
        WLink { icon: "sports_esports"; title: "Start Steam at sign-in"; description: (Config.options.extras.steamTray ? "On" : "Off") + " · Apps › Startup"; page: "apps"; sub: "startup" }
    }

    // Phoenix (2026-10-15): settings moved here from illogical-impulse's original settings
    SServices {}
    SOverlay {}
}
