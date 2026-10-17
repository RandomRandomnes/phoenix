// Generated 2026-10-15 from illogical-impulse's InterfaceConfig.qml (Phoenix: the old settings moved into
// the Windows-style settings). Edit freely; it isn't regenerated.
import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ColumnLayout {
    id: page
    Layout.fillWidth: true
    spacing: 8

    WCSection {
            icon: "lock"
            title: Translation.tr("Lock screen")
            shape: MaterialShape.Shape.Pentagon

            WCGroup {
                WCSwitch {
                    buttonIcon: "water_drop"
                    text: Translation.tr("Use Hyprlock (instead of Quickshell)")
                    checked: Config.options.lock.useHyprlock
                    onToggled: checked => { Config.options.lock.useHyprlock = checked }
                }
                WCSwitch {
                    buttonIcon: "account_circle"
                    text: Translation.tr("Launch on startup")
                    checked: Config.options.lock.launchOnStartup
                    onToggled: checked => { Config.options.lock.launchOnStartup = checked }
                }
                WCSwitch {
                    buttonIcon: "widgets"
                    enabled: WM.compositor !== "niri"
                    text: Translation.tr("Show Widgets")
                    checked: Config.options.lock.showWidgets
                    onToggled: checked => { Config.options.lock.showWidgets = checked }
                }
                WCSwitch {
                    buttonIcon: "tools_installation_kit"
                    text: Translation.tr("Show Toolbars")
                    checked: Config.options.lock.showToolbars
                    onToggled: checked => { Config.options.lock.showToolbars = checked }
                }
                WCSwitch {
                    buttonIcon: "music_note"
                    enabled: Config.options.lock.showToolbars
                    text: Translation.tr("Show media player info")
                    checked: Config.options.lock.showMedia
                    onToggled: checked => { Config.options.lock.showMedia = checked }
                }
            }

            WCSubsection {
                title: Translation.tr("Security")
                WCGroup {
                    WCSwitch {
                        buttonIcon: "settings_power"
                        text: Translation.tr("Require password to power off/restart")
                        checked: Config.options.lock.security.requirePasswordToPower
                        onToggled: checked => { Config.options.lock.security.requirePasswordToPower = checked }
                    }
                    WCSwitch {
                        buttonIcon: "key_vertical"
                        text: Translation.tr("Also unlock keyring")
                        checked: Config.options.lock.security.unlockKeyring
                        onToggled: checked => { Config.options.lock.security.unlockKeyring = checked }
                    }
                }
            }

            WCSubsection {
                title: Translation.tr("Style: General")
                WCGroup {
                    WCSwitch {
                        buttonIcon: "center_focus_weak"
                        text: Translation.tr("Center clock")
                        checked: Config.options.lock.centerClock
                        onToggled: checked => { Config.options.lock.centerClock = checked }
                    }
                    WCSwitch {
                        buttonIcon: "info"
                        text: Translation.tr('Show "Locked" text')
                        checked: Config.options.lock.showLockedText
                        onToggled: checked => { Config.options.lock.showLockedText = checked }
                    }
                    WCSwitch {
                        buttonIcon: "shapes"
                        text: Translation.tr("Use varying shapes for password characters")
                        checked: Config.options.lock.materialShapeChars
                        onToggled: checked => { Config.options.lock.materialShapeChars = checked }
                    }
                }
            }

            WCSubsection {
                title: Translation.tr("Style: Blurred")
                WCGroup {
                    // Blur on/off: Settings › Personalization › Lock screen (one place for it, 2026-10-16)
                    WCSpin {
                        icon: "deblur"
                        text: Translation.tr("Samples")
                        value: Config.options.lock.blur.size
                        from: 20; to: 200; stepSize: 10
                        onEdited: value => { Config.options.lock.blur.size = value }
                    }
                    WCSpin {
                        icon: "loupe"
                        text: Translation.tr("Extra wallpaper zoom (%)")
                        value: Config.options.lock.blur.extraZoom * 100
                        from: 1; to: 150; stepSize: 2
                        onEdited: value => { Config.options.lock.blur.extraZoom = value / 100 }
                    }
                }
            }
        }

}
