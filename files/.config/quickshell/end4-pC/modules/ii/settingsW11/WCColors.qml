import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// Phoenix (2026-10-15): illogical-impulse's ColorSelectionArray in a Windows-style card (icon, text, currentValue,
// options, selected(newValue)); the swatches themselves are illogical-impulse's.
WCard {
    id: root
    property string text: "Color"
    property string currentValue: ""
    property var options: ["primary", "secondary", "tertiary", "primaryContainer", "secondaryContainer", "tertiaryContainer", "layer1", "layer0"]
    property bool showLabel: true
    property real itemSpacing: 10
    property bool showTooltip: false
    signal selected(string newValue)

    icon: "palette"
    title: root.showLabel ? root.text : ""

    ColorSelectionArray {
        showLabel: false
        currentValue: root.currentValue
        options: root.options
        itemSpacing: root.itemSpacing
        showTooltip: root.showTooltip
        onSelected: v => root.selected(v)
    }
}
