import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models.hyprland
import qs.modules.common.models.quickToggles

WPage {
    id: page
    GameModeToggle { id: gameMode }
    HyprlandConfigOption { id: tearing; key: "general:allow_tearing" }

    WSection {
        WToggle {
            icon: "sports_esports"
            title: "Game Mode"
            description: "Turns off animations and effects for lower latency"
            keywords: "blur shadows gaps rounded corners tearing"
            checked: gameMode.toggled
            onToggled: gameMode.mainAction()
        }
        WToggle {
            icon: "auto_mode"
            title: "Turn on Game Mode automatically"
            description: "While a fullscreen game is focused"
            checked: Config.options.extras.gameModeAuto
            onToggled: v => Config.options.extras.gameModeAuto = v
        }
        WToggle {
            visible: Config.options.extras.wallpaperEngine
            icon: "wallpaper"
            title: "Stop Wallpaper Engine in Game Mode"
            description: "Frees the graphics card for the game"
            checked: Config.options.extras.gameModeWallpaper
            onToggled: v => Config.options.extras.gameModeWallpaper = v
        }
        WToggle {
            visible: PowerProfiles.hasPerformanceProfile
            icon: "speed"
            title: "Best performance power mode in Game Mode"
            description: "Restored when Game Mode turns off"
            checked: Config.options.extras.gameModePerformance
            onToggled: v => Config.options.extras.gameModePerformance = v
        }
        WCombo {
            icon: "bolt"
            title: "Power mode"
            model: [
                { displayName: "Best power efficiency", value: PowerProfile.PowerSaver },
                { displayName: "Balanced", value: PowerProfile.Balanced },
            ].concat(PowerProfiles.hasPerformanceProfile || PowerProfiles.profile === PowerProfile.Performance
                    ? [{ displayName: "Best performance", value: PowerProfile.Performance }] : [])   // shown when active (was "—")
            currentValue: PowerProfiles.profile
            onSelected: v => PowerProfiles.profile = v
        }
    }

    WSection {
        title: "Notifications"
        WToggle {
            icon: "do_not_disturb_on"
            title: "Do not disturb while playing"
            keywords: "pop-ups"
            description: "Still kept in the notification center"
            checked: Config.options.extras.autoDnd
            onToggled: v => Config.options.extras.autoDnd = v
        }
        WToggle {
            enabled: Config.options.extras.autoDnd
            opacity: enabled ? 1 : 0.5
            icon: "screen_share"
            title: "Also while sharing your screen"
            keywords: "discord obs"
            checked: Config.options.extras.autoDndScreenShare
            onToggled: v => Config.options.extras.autoDndScreenShare = v
        }
    }

    WSection {
        title: "Display"
        WToggle {
            icon: "bolt"
            title: "Allow screen tearing in games"
            keywords: "immediate"
            description: "Lower input latency in games that ask for it"
            checked: !!tearing.value
            onToggled: v => { tearing.value = v; tearing.setValue(v ? 1 : 0); }
        }
        WToggle {
            icon: "fullscreen"
            title: "Pause the animated wallpaper behind fullscreen apps"
            checked: Config.options.background.hideWhenFullscreen
            onToggled: v => Config.options.background.hideWhenFullscreen = v
        }
        WLink { icon: "speed"; title: "Variable refresh rate"; description: "In Display settings"; page: "system"; sub: "display" }
    }

    WSection {
        title: "Overlays"
        WToggle {
            icon: "my_location"
            title: "Crosshair overlay"
            description: "In the middle of the screen"
            checked: GlobalStates.crosshairOpen
            onToggled: v => GlobalStates.crosshairOpen = v
        }
        WCard {
            icon: "code"
            title: "Crosshair code"
            description: "Valorant-style crosshair code"
            Rectangle {
                implicitWidth: 280; implicitHeight: 34
                radius: 12
                color: Appearance.colors.colLayer4
                TextInput {
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    verticalAlignment: Text.AlignVCenter
                    clip: true
                    color: Appearance.colors.colOnLayer3
                    font.family: Appearance.font.family.monospace
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    text: Config.options.crosshair.code
                    onEditingFinished: Config.options.crosshair.code = text
                }
            }
        }
    }

    WSection {
        title: "Related"
        WLink { icon: "sports_esports"; title: "Open Steam"; chevronIcon: "open_in_new"; action: () => { Quickshell.execDetached(["steam"]); GlobalStates.settingsOpen = false; } }
        WLink { icon: "notifications_off"; title: "Do not disturb"; page: "system"; sub: "notifications" }
    }
}
