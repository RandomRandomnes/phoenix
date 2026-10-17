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
            icon: "call_to_action"
            title: Translation.tr("Dock")
            shape: MaterialShape.Shape.Cookie6Sided

            WCGroup {
                WCSwitch {
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.dock.enable
                    onToggled: checked => { Config.options.dock.enable = checked }
                }
                WCSwitch {
                    buttonIcon: "background_dot_small"
                    text: Translation.tr("Background")
                    checked: Config.options.dock.showBackground
                    onToggled: checked => { Config.options.dock.showBackground = checked }
                }
                WCSwitch {
                    buttonIcon: "highlight_mouse_cursor"
                    text: Translation.tr("Hover to reveal")
                    checked: Config.options.dock.hoverToReveal
                    onToggled: checked => { Config.options.dock.hoverToReveal = checked }
                }
                WCSwitch {
                    buttonIcon: "push_pin"
                    text: Translation.tr("Pinned on startup")
                    checked: Config.options.dock.pinnedOnStartup
                    onToggled: checked => { Config.options.dock.pinnedOnStartup = checked }
                }
            }

            WCSubsection {
                title: Translation.tr("Appearance")
                WCGroup {
                    WCSelection {
                        text: Translation.tr("Style")
                        icon: "dock_to_bottom"
                        currentValue: Config.options.dock.style
                        onSelected: newValue => { Config.options.dock.style = newValue }
                        options: [
                            { displayName: Translation.tr("Float"), icon: "call_to_action", value: "float" },
                            { displayName: Translation.tr("Hug"), icon: "dock_to_bottom", value: "hug" }
                        ]
                    }
                    WCSelection {
                        text: Translation.tr("Position")
                        icon: "dock_to_bottom"
                        currentValue: Config.options.dock.position
                        onSelected: newValue => { Config.options.dock.position = newValue }
                        options: [
                            { displayName: Translation.tr("Left"), icon: "dock_to_left", value: "left" },
                            { displayName: Translation.tr("Bottom"), icon: "dock_to_bottom", value: "bottom" },
                            { displayName: Translation.tr("Right"), icon: "dock_to_right", value: "right" }
                        ]
                    }
                    WCSpin {
                        icon: "rounded_corner"
                        text: Translation.tr("Corner radius")
                        value: Config.options.dock.radius
                        from: 0
                        to: 40
                        stepSize: 1
                        onEdited: value => { Config.options.dock.radius = value }
                    }
                    WCColors {
                        icon: "format_paint"
                        text: Translation.tr("Background color")
                        options: ["layer0", "layer1", "primaryContainer", "secondaryContainer", "tertiaryContainer", "primary", "secondary", "tertiary"]
                        currentValue: Config.options.dock.backgroundColor
                        onSelected: newValue => { Config.options.dock.backgroundColor = newValue }
                    }
                    WCSwitch {
                        enabled: Config.options.dock.style === "hug"
                        buttonIcon: "filter_frames"
                        text: Translation.tr("Follow frame color")
                        checked: Config.options.dock.followFrameColor
                        onToggled: checked => { Config.options.dock.followFrameColor = checked }
                    }
                    WCSwitch {
                        enabled: Config.options.dock.style !== "hug"
                        buttonIcon: "border_style"
                        text: Translation.tr("Border")
                        checked: Config.options.dock.showBorder
                        onToggled: checked => { Config.options.dock.showBorder = checked }
                    }
                    WCSpin {
                        enabled: Config.options.dock.showBorder && Config.options.dock.style !== "hug"
                        icon: "line_weight"
                        text: Translation.tr("Border width")
                        value: Config.options.dock.borderWidth
                        from: 1
                        to: 10
                        stepSize: 1
                        onEdited: value => { Config.options.dock.borderWidth = value }
                    }
                    WCColors {
                        enabled: Config.options.dock.showBorder && Config.options.dock.style !== "hug"
                        icon: "format_paint"
                        text: Translation.tr("Border color")
                        options: ["layer0Border", "primary", "secondary", "tertiary", "primaryContainer", "secondaryContainer", "tertiaryContainer", "layer1"]
                        currentValue: Config.options.dock.borderColor
                        onSelected: newValue => { Config.options.dock.borderColor = newValue }
                    }
                }
            }


            WCSubsection {
                title: Translation.tr("Icons")
                WCGroup {
                    WCSwitch {
                        buttonIcon: "preview"
                        text: Translation.tr("Window previews")
                        checked: Config.options.dock.showPreviews
                        onToggled: checked => { Config.options.dock.showPreviews = checked }
                    }
                    WCSpin {
                        icon: "photo_size_select_large"
                        text: Translation.tr("Icon size")
                        value: Config.options.dock.iconSize
                        from: 20
                        to: 48
                        stepSize: 1
                        onEdited: value => { Config.options.dock.iconSize = value }
                    }
                    WCSpin {
                        icon: "space_bar"
                        text: Translation.tr("Icon spacing")
                        value: Config.options.dock.iconSpacing
                        from: 0
                        to: 12
                        stepSize: 1
                        onEdited: value => { Config.options.dock.iconSpacing = value }
                    }
                }
            }

            WCSubsection {
                title: Translation.tr("Buttons & Media")
                WCGroup {
                    WCSwitch {
                        buttonIcon: "music_note"
                        text: Translation.tr("Media Player")
                        checked: Config.options.dock.showMedia
                        onToggled: checked => { Config.options.dock.showMedia = checked }
                    }
                    WCSwitch {
                        buttonIcon: "keep"
                        text: Translation.tr("Show Pin Button")
                        checked: Config.options.dock.showPinButton
                        onToggled: checked => { Config.options.dock.showPinButton = checked }
                    }
                    WCSwitch {
                        buttonIcon: "apps"
                        text: Translation.tr("Show Apps Button")
                        checked: Config.options.dock.showAppsButton
                        onToggled: checked => { Config.options.dock.showAppsButton = checked }
                    }
                    WCSwitch {
                        buttonIcon: "colors"
                        text: Translation.tr("Tint app icons")
                        checked: Config.options.dock.monochromeIcons
                        onToggled: checked => { Config.options.dock.monochromeIcons = checked }
                    }
                }
            }
        }

}
