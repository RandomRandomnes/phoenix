// Generated 2026-10-15 from illogical-impulse's GeneralConfig.qml (Phoenix: the old settings moved into
// the Windows-style settings). Edit freely; it isn't regenerated.
import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ColumnLayout {
    id: page
    Layout.fillWidth: true
    spacing: 8

    Process {
        id: translationProc
        property string locale: ""
        command: [Directories.aiTranslationScriptPath, translationProc.locale]
    }

    WCSection {
            icon: "palette"
            shape: MaterialShape.Shape.Pentagon
            title: Translation.tr("System Appearance")

            WCGroup {
                WCCombo {
                    Layout.fillWidth: true
                    buttonIcon: "category"
                    text: Translation.tr("Icon theme")
                    fieldWidth: 260
                    fixedWidth: true
                    searchable: true
                    model: SystemAppearance.toOptions(SystemAppearance.iconThemes)
                    currentValue: SystemAppearance.iconTheme
                    onSelected: newValue => SystemAppearance.setIcons(newValue)
                }
                WCCombo {
                    Layout.fillWidth: true
                    buttonIcon: "mouse"
                    text: Translation.tr("Cursor theme")
                    fieldWidth: 260
                    fixedWidth: true
                    searchable: true
                    model: SystemAppearance.toOptions(SystemAppearance.cursorThemes)
                    currentValue: SystemAppearance.cursorTheme
                    onSelected: newValue => SystemAppearance.setCursor(newValue, SystemAppearance.cursorSize)
                }
                WCSpin {
                    icon: "ads_click"
                    text: Translation.tr("Cursor size")
                    value: SystemAppearance.cursorSize
                    from: 16
                    to: 64
                    stepSize: 2
                    onEdited: value => {
                        if (value !== SystemAppearance.cursorSize) SystemAppearance.setCursor(SystemAppearance.cursorTheme, value)
                    }
                }
                WCCombo {
                    Layout.fillWidth: true
                    buttonIcon: "text_fields"
                    text: Translation.tr("System font")
                    fieldWidth: 260
                    fixedWidth: true
                    searchable: true
                    model: SystemAppearance.toOptions(SystemAppearance.fonts)
                    currentValue: SystemAppearance.fontFamily
                    onSelected: newValue => SystemAppearance.setFont("ui", newValue, SystemAppearance.fontSize)
                }
                WCSpin {
                    icon: "format_size"
                    text: Translation.tr("System font size")
                    value: SystemAppearance.fontSize
                    from: 8
                    to: 20
                    stepSize: 1
                    onEdited: value => {
                        if (value !== SystemAppearance.fontSize) SystemAppearance.setFont("ui", SystemAppearance.fontFamily, value)
                    }
                }
                WCCombo {
                    Layout.fillWidth: true
                    buttonIcon: "terminal"
                    text: Translation.tr("Monospace font")
                    fieldWidth: 260
                    fixedWidth: true
                    searchable: true
                    model: SystemAppearance.toOptions(SystemAppearance.fonts)
                    currentValue: SystemAppearance.monoFamily
                    onSelected: newValue => SystemAppearance.setFont("mono", newValue, SystemAppearance.monoSize)
                }
                WCSpin {
                    icon: "format_size"
                    text: Translation.tr("Monospace font size")
                    value: SystemAppearance.monoSize
                    from: 8
                    to: 20
                    stepSize: 1
                    onEdited: value => {
                        if (value !== SystemAppearance.monoSize) SystemAppearance.setFont("mono", SystemAppearance.monoFamily, value)
                    }
                }
            }
        }

}
