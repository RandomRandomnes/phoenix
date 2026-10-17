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
            icon: "palette"
            shape: MaterialShape.Shape.Cookie9Sided
            title: Translation.tr("Color Schemes")

            WCGroup {
                WCCombo {
                    Layout.fillWidth: true
                    buttonIcon: "format_paint"
                    text: Translation.tr("Color scheme")
                    description: Translation.tr("Material follows your wallpaper")
                    fieldWidth: 220
                    fixedWidth: true
                    model: ColorSchemes.schemeOptions()
                    currentValue: ColorSchemes.current
                    onSelected: newValue => ColorSchemes.setScheme(newValue)
                }
                RowLayout {
                    enabled: ColorSchemes.currentData !== null
                    opacity: enabled ? 1 : 0.55
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                    spacing: 10
                    MaterialSymbol {
                        text: "brush"
                        iconSize: Appearance.font.pixelSize.normal + 5
                        color: Appearance.colors.colOnLayer0
                    }
                    StyledText {
                        text: Translation.tr("Accent")
                        color: Appearance.colors.colOnLayer0
                    }
                    Item { Layout.fillWidth: true }
                    CustomColorSelectionArray {
                        spacing: 4
                        swatchSize: 36
                        options: ColorSchemes.accentOptions()
                        currentValue: ColorSchemes.currentAccent("primary")
                        onSelected: newValue => ColorSchemes.setAccent("primary", newValue)
                    }
                }
                RowLayout {
                    enabled: ColorSchemes.currentData !== null
                    opacity: enabled ? 1 : 0.55
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                    spacing: 10
                    MaterialSymbol {
                        text: "colors"
                        iconSize: Appearance.font.pixelSize.normal + 5
                        color: Appearance.colors.colOnLayer0
                    }
                    StyledText {
                        text: Translation.tr("Secondary")
                        color: Appearance.colors.colOnLayer0
                    }
                    Item { Layout.fillWidth: true }
                    CustomColorSelectionArray {
                        spacing: 4
                        swatchSize: 36
                        options: ColorSchemes.accentOptions()
                        currentValue: ColorSchemes.currentAccent("secondary")
                        onSelected: newValue => ColorSchemes.setAccent("secondary", newValue)
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                    spacing: 8
                    RippleButtonWithIcon {
                        Layout.fillWidth: true
                        materialIcon: "add"
                        mainText: Translation.tr("Add scheme")
                        onClicked: ColorSchemes.addScheme()
                        colBackground: Appearance.colors.colSecondaryContainer
                        colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                        colRipple: Appearance.colors.colSecondaryContainerActive
                    }
                    RippleButtonWithIcon {
                        Layout.fillWidth: true
                        materialIcon: "folder_open"
                        mainText: Translation.tr("Open folder")
                        onClicked: ColorSchemes.openFolder()
                        colBackground: Appearance.colors.colSecondaryContainer
                        colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                        colRipple: Appearance.colors.colSecondaryContainerActive
                    }
                    RippleButtonWithIcon {
                        Layout.fillWidth: true
                        materialIcon: "refresh"
                        mainText: Translation.tr("Reload")
                        onClicked: ColorSchemes.reload()
                        colBackground: Appearance.colors.colSecondaryContainer
                        colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                        colRipple: Appearance.colors.colSecondaryContainerActive
                    }
                }
            }
        }

    // Transparency: Settings › Personalization › Colors (one place for it, 2026-10-16)

    WCSection {
            icon: "colors"
            title: Translation.tr("Color generation")
            shape: MaterialShape.Shape.VerySunny

            WCGroup {
                WCSwitch {
                    buttonIcon: "hardware"
                    text: Translation.tr("Shell & utilities")
                    checked: Config.options.appearance.wallpaperTheming.enableAppsAndShell
                    onToggled: checked => { Config.options.appearance.wallpaperTheming.enableAppsAndShell = checked }
                }
                WCSwitch {
                    buttonIcon: "tv_options_input_settings"
                    text: Translation.tr("Qt apps")
                    checked: Config.options.appearance.wallpaperTheming.enableQtApps
                    onToggled: checked => { Config.options.appearance.wallpaperTheming.enableQtApps = checked }
                }
                WCSwitch {
                    buttonIcon: "terminal"
                    text: Translation.tr("Terminal")
                    checked: Config.options.appearance.wallpaperTheming.enableTerminal
                    onToggled: checked => { Config.options.appearance.wallpaperTheming.enableTerminal = checked }
                }
                WCGroup {
                    uniform: true
                    WCSwitch {
                        buttonIcon: "dark_mode"
                        text: Translation.tr("Force dark mode in terminal")
                        checked: Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode
                        onToggled: checked => { Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode = checked }
                    }
                }
                WCSpin {
                    icon: "invert_colors"
                    text: Translation.tr("Terminal: Harmony (%)")
                    value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony * 100
                    from: 0; to: 100; stepSize: 10
                    onEdited: value => { Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony = value / 100 }
                }
                WCSpin {
                    icon: "gradient"
                    text: Translation.tr("Terminal: Harmonize threshold")
                    value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold
                    from: 0; to: 100; stepSize: 10
                    onEdited: value => { Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold = value }
                }
                WCSpin {
                    icon: "format_color_text"
                    text: Translation.tr("Terminal: Foreground boost (%)")
                    value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost * 100
                    from: 0; to: 100; stepSize: 10
                    onEdited: value => { Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost = value / 100 }
                }
            }
        }

}
