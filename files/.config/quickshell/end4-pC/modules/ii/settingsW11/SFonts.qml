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
            icon: "text_format"
            shape: MaterialShape.Shape.Arrow
            title: Translation.tr("Fonts")

            WCGroup {
                WCCombo {
                    Layout.fillWidth: true
                    buttonIcon: "font_download"
                    text: Translation.tr("Main font")
                    fieldWidth: 260
                    fixedWidth: true
                    searchable: true
                    model: SystemAppearance.fontOptions(Config.options.appearance.fonts.main)
                    currentValue: Config.options.appearance.fonts.main
                    onSelected: newValue => { Config.options.appearance.fonts.main = newValue }
                }
                WCCombo {
                    Layout.fillWidth: true
                    buttonIcon: "123"
                    text: Translation.tr("Numbers font")
                    fieldWidth: 260
                    fixedWidth: true
                    searchable: true
                    model: SystemAppearance.fontOptions(Config.options.appearance.fonts.numbers)
                    currentValue: Config.options.appearance.fonts.numbers
                    onSelected: newValue => { Config.options.appearance.fonts.numbers = newValue }
                }
                WCCombo {
                    Layout.fillWidth: true
                    buttonIcon: "title"
                    text: Translation.tr("Title font")
                    fieldWidth: 260
                    fixedWidth: true
                    searchable: true
                    model: SystemAppearance.fontOptions(Config.options.appearance.fonts.title)
                    currentValue: Config.options.appearance.fonts.title
                    onSelected: newValue => { Config.options.appearance.fonts.title = newValue }
                }
                WCCombo {
                    Layout.fillWidth: true
                    buttonIcon: "space_bar"
                    text: Translation.tr("Monospace font")
                    fieldWidth: 260
                    fixedWidth: true
                    searchable: true
                    model: SystemAppearance.fontOptions(Config.options.appearance.fonts.monospace)
                    currentValue: Config.options.appearance.fonts.monospace
                    onSelected: newValue => { Config.options.appearance.fonts.monospace = newValue }
                }
                WCCombo {
                    Layout.fillWidth: true
                    buttonIcon: "emoticon"
                    text: Translation.tr("Nerd Fonts icons")
                    fieldWidth: 260
                    fixedWidth: true
                    searchable: true
                    model: SystemAppearance.fontOptions(Config.options.appearance.fonts.iconNerd)
                    currentValue: Config.options.appearance.fonts.iconNerd
                    onSelected: newValue => { Config.options.appearance.fonts.iconNerd = newValue }
                }
                WCCombo {
                    Layout.fillWidth: true
                    buttonIcon: "book_ribbon"
                    text: Translation.tr("Reading font")
                    fieldWidth: 260
                    fixedWidth: true
                    searchable: true
                    model: SystemAppearance.fontOptions(Config.options.appearance.fonts.reading)
                    currentValue: Config.options.appearance.fonts.reading
                    onSelected: newValue => { Config.options.appearance.fonts.reading = newValue }
                }
                WCCombo {
                    Layout.fillWidth: true
                    buttonIcon: "mood_heart"
                    text: Translation.tr("Expressive font")
                    fieldWidth: 260
                    fixedWidth: true
                    searchable: true
                    model: SystemAppearance.fontOptions(Config.options.appearance.fonts.expressive)
                    currentValue: Config.options.appearance.fonts.expressive
                    onSelected: newValue => { Config.options.appearance.fonts.expressive = newValue }
                }
            }
        }

}
