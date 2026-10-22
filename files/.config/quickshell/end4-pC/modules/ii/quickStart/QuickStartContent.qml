// Quick Start content (2026-10-03, ours; not upstream; a window of the main shell since 2026-10-16:
// modules/ii/quickStart/QuickStart.qml): the "after installing" part of the quick start guide as a small app.
// Opens when the first-time setup wizard finishes, from the app menu (~/.local/share/applications/quick-start.desktop)
// and from Settings › Extras. The full guide with the USB/install steps is ~/.local/share/quick-start/index.html
// (also on the USB stick as clone/QUICK-START.html); keep the two in step.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.settingsW11

Item {
    id: root
    property string startPage: ""
    signal done()   // "Finish" on the last page: the window closes (never Qt.quit(): this runs inside the shell)
    Rectangle { anchors.fill: parent; color: Appearance.m3colors.m3background }

    readonly property string home: Quickshell.env("HOME")
    Component.onCompleted: {
        const start = root.pages.findIndex(pg => pg.id === root.startPage)
        if (start > 0) root.page = start
    }

    // Pages: blocks are {p}, {h}, {keys: [..], what}, {row: title, text} (a card) and {open: label, cmd}.
    readonly property var pages: [
        { id: "welcome", title: "Welcome", icon: "waving_hand", heading: "Welcome to Phoenix", blocks: [
            { p: "A Windows-style desktop for Arch Linux, built on Hyprland and illogical-impulse (unofficial)." },
            { row: "Super key", text: "The Windows key; Super+/ lists every shortcut" },
            { row: "Settings", text: "Super+I" },
            { row: "This guide", text: "Super, type \"Quick Start\"" },
        ]},
        { id: "keys", title: "Shortcuts", icon: "keyboard_command_key", heading: "Keyboard shortcuts", blocks: [
            { h: "Windows and workspaces" },
            { keys: ["Super"], what: "Application menu and search" },
            { keys: ["Super", "Tab"], what: "All workspaces and windows" },
            { keys: ["Super", "Q"], what: "Close window" },
            { keys: ["Super", "D"], what: "Maximize or restore window" },
            { keys: ["Super", "1…0"], what: "Switch workspace" },
            { keys: ["Super", "L"], what: "Lock" },
            { h: "Apps" },
            { keys: ["Super", "W"], what: "Browser" },
            { keys: ["Super", "E"], what: "Files" },
            { keys: ["Super", "Enter"], what: "Terminal" },
            { keys: ["Super", "I"], what: "Settings" },
            { keys: ["Ctrl", "Shift", "Esc"], what: "Task Manager" },
            { h: "Shell" },
            { keys: ["Super", "A"], what: "Left sidebar: AI chat, translator" },
            { keys: ["Super", "N"], what: "Right sidebar: quick settings, notifications" },
            { keys: ["Super", "V"], what: "Clipboard history" },
            { keys: ["Super", "."], what: "Emoji" },
            { keys: ["Super", "Shift", "S"], what: "Screenshot of an area" },
            { keys: ["Ctrl", "Super", "T"], what: "Change wallpaper" },
            { keys: ["Shift", "Super", "Alt", "/"], what: "Setup assistant" },
            { keys: ["Super", "/"], what: "List every shortcut" },
        ]},
        { id: "windows", title: "Windows", icon: "select_window", heading: "Windows", blocks: [
            { row: "Red", text: "Close" },
            { row: "Green", text: "Maximize or restore (or double-click the title bar)" },
            { row: "Yellow", text: "Minimize; click the dock icon to restore" },
            { p: "Tiling instead: Settings › Extras › Windows-style windows off." },
        ]},
        { id: "settings", title: "Settings and profiles", icon: "settings", heading: "Settings and profiles", blocks: [
            { p: "One switch per added feature; off means standard illogical-impulse." },
            { row: "Live system graphs", text: "CPU, GPU and RAM on the taskbar" },
            { row: "Wallpaper Engine background", text: "Off by default; see Extras" },
            { row: "Use a profile file", text: "Applies a look and feature set; backs up your settings first" },
            { row: "Share my setup", text: "Saves your setup as a profile file" },
            { p: "More profiles: github.com/RandomRandomnes/phoenix" },
            { open: "Open Settings", cmd: ["qs", "-c", "end4-pC", "ipc", "call", "settings", "open"] },
        ]},
        { id: "apps", title: "Applications", icon: "apps", heading: "Applications", blocks: [
            { p: "Firefox is preinstalled. Add apps in the setup assistant (Shift+Super+Alt+/), or with pacman or flatpak." },
            { row: "Gaming pack", text: "Steam, MangoHud, GameMode, ProtonUp-Qt" },
            { row: "Productivity pack", text: "LibreOffice, Thunderbird, Obsidian, Code - OSS, KeePassXC" },
        ]},
        { id: "updates", title: "Updates", icon: "system_update_alt", heading: "Updates", blocks: [
            { p: "The taskbar's update button installs everything waiting. Details: Settings › Update." },
            { row: "System fixes", text: "For Arch, Hyprland and Quickshell updates; always installed" },
            { row: "Custom fixes (2.1, 2.11, …)", text: "Phoenix fixes, if turned on. Settings › Update › Undo last reverts one" },
            { row: "Major versions (3, 4, …)", text: "Never automatic: offered in Settings › Update" },
            { row: "Desktop broken after an update", text: "Settings › Update › Restore points" },
        ]},
        { id: "startup", title: "Boot menu", icon: "restart_alt", heading: "Boot menu and Windows", blocks: [
            { p: "Starts without a menu. Windows: firmware boot menu (F8, F11 or F12 at power-on)." },
            { row: "Add a menu", text: "Setup assistant › Drivers and updates" },
            { row: "rEFInd", text: "Graphical; finds Windows on any disk" },
            { row: "systemd-boot", text: "Simple; lists Windows only on the same EFI partition" },
            { row: "GRUB", text: "Text menu; only with Secure Boot off" },
            { row: "No menu (direct)", text: "Back to no menu; nothing is deleted" },
        ]},
        { id: "extras", title: "Extras", icon: "auto_awesome", heading: "Extras", blocks: [
            { row: "Wallpaper Engine", text: "Needs Wallpaper Engine from Steam; turn it on in Settings › Extras" },
            { row: "KDE Plasma", text: "Turn on the KDE switch in Settings › Extras" },
            { row: "Encrypted disk", text: "TPM unlock commands: ~/WELCOME-phoenix.txt" },
        ]},
        { id: "help", title: "Troubleshooting", icon: "help", heading: "Troubleshooting", blocks: [
            { row: "Black screen (NVIDIA)", text: "Ctrl+Alt+F2, log in, sudo pacman -S nvidia-open-dkms nvidia-utils linux-headers, reboot" },
            { row: "Black screen after an update", text: "Ctrl+Alt+F2, log in, sudo pacman -Syu, reboot" },
            { row: "Desktop broken after an update", text: "Settings › Update › Restore points; for a bug fix, Undo last" },
            { row: "Text too small or too large", text: "Settings › System › Display › Scale" },
            { row: "No Wi-Fi", text: "Right sidebar (Super+N) › Wi-Fi" },
            { row: "No GPU graph", text: "Settings › Extras › Live system graphs" },
            { row: "Install on another PC", text: "Full guide: phoenix/QUICK-START.html on the USB stick" },
            { open: "Open the full guide", cmd: ["xdg-open", Quickshell.env("HOME") + "/.local/share/quick-start/index.html"] },
        ]},
    ]
    property int page: 0
    readonly property var cur: pages[page]

    component KeyCap: Rectangle {
        required property string label
        implicitWidth: Math.max(34, keyText.implicitWidth + 18)
        implicitHeight: 30
        radius: 8
        color: Appearance.colors.colLayer3
        border.width: 1
        border.color: Appearance.colors.colOutlineVariant
        StyledText {
            id: keyText
            anchors.centerIn: parent
            text: parent.label
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer2
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {   // page list
            Layout.fillHeight: true
            Layout.preferredWidth: 230
            color: "transparent"   // Material look (2026-10-15): the list sits on the window background, like Settings' rail
            ColumnLayout {
                anchors { fill: parent; margins: 20 }
                spacing: 4
                RowLayout {
                    Layout.bottomMargin: 12
                    spacing: 10
                    MaterialSymbol { text: "menu_book"; iconSize: 24; fill: 1; color: Appearance.colors.colPrimary }
                    StyledText {
                        text: "Quick Start"
                        font.family: Appearance.font.family.expressive
                        font.pixelSize: Appearance.font.pixelSize.larger
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer0
                    }
                }
                Repeater {
                    model: root.pages
                    RippleButton {
                        id: navButton
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: 40
                        buttonRadius: height / 2
                        colBackground: index === root.page ? Appearance.colors.colSecondaryContainer : "transparent"
                        colBackgroundHover: index === root.page ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colLayer1Hover
                        onClicked: root.page = index
                        contentItem: RowLayout {
                            spacing: 12
                            MaterialSymbol {
                                Layout.leftMargin: 6
                                text: navButton.modelData.icon
                                iconSize: 20
                                fill: navButton.index === root.page ? 1 : 0
                                color: navButton.index === root.page ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer0
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: navButton.modelData.title
                                font.weight: navButton.index === root.page ? Font.DemiBold : Font.Normal
                                color: navButton.index === root.page ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer0
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

            ColumnLayout {   // current page
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

                WPage {
                    id: body
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    maxContentWidth: 760
                    Repeater {
                        model: root.cur.blocks
                        Loader {
                            id: block
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            // cards right after each other join into one grouped list (4 px apart, like Settings)
                            Layout.topMargin: modelData.row !== undefined && index > 0
                                && root.cur.blocks[index - 1].row !== undefined ? -18 : 0
                            sourceComponent: modelData.p !== undefined ? para : modelData.h !== undefined ? heading
                                : modelData.keys !== undefined ? keys : modelData.row !== undefined ? card : openButton
                            Component {
                                id: para
                                StyledText {
                                    wrapMode: Text.WordWrap
                                    text: block.modelData.p
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnLayer0
                                }
                            }
                            Component {
                                id: heading
                                StyledText {
                                    topPadding: 8
                                    text: block.modelData.h
                                    font.pixelSize: Appearance.font.pixelSize.large
                                    font.weight: Font.DemiBold
                                    color: Appearance.colors.colOnLayer0
                                }
                            }
                            Component {
                                id: keys
                                RowLayout {
                                    spacing: 6
                                    Item {   // keys column, fixed width so descriptions line up
                                        Layout.preferredWidth: 230
                                        implicitHeight: 30
                                        Row {
                                            spacing: 6
                                            Repeater {
                                                model: block.modelData.keys
                                                Row {
                                                    required property var modelData
                                                    required property int index
                                                    spacing: 6
                                                    StyledText {
                                                        visible: index > 0
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        text: "+"
                                                        color: Appearance.colors.colSubtext
                                                    }
                                                    KeyCap { label: modelData }
                                                }
                                            }
                                        }
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        text: block.modelData.what
                                        color: Appearance.colors.colOnLayer0
                                    }
                                }
                            }
                            Component {
                                id: card
                                WCard {
                                    title: block.modelData.row
                                    description: block.modelData.text
                                }
                            }
                            Component {
                                id: openButton
                                RowLayout {
                                    WButton {
                                        accent: true
                                        buttonText: block.modelData.open
                                        onClicked: Quickshell.execDetached(block.modelData.cmd)
                                    }
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    WButton {
                        visible: root.page > 0
                        buttonText: "Back"
                        onClicked: root.page--
                    }
                    Item { Layout.fillWidth: true }
                    WButton {
                        accent: true
                        buttonText: root.page < root.pages.length - 1 ? "Next" : "Done"
                        onClicked: root.page < root.pages.length - 1 ? root.page++ : root.done()
                    }
                }
            }
        }
    }
}
