import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// Phoenix (2026-10-15): illogical-impulse's ConfigSlider in the Windows-style look. Same API: text, buttonIcon, value,
// from, to, stepSize, stopIndicatorValues, usePercentTooltip, moved().
WCard {
    id: root
    property string text: ""
    property string buttonIcon: ""
    property real value: 0
    property real from: 0
    property real to: 1
    property real stepSize: 0
    property var stopIndicatorValues: []
    property bool usePercentTooltip: true
    property bool showLabel: true
    property real textWidth: 120
    readonly property bool pressed: slider.pressed
    signal moved()

    title: root.showLabel ? root.text : ""
    icon: root.buttonIcon
    opacity: enabled ? 1 : 0.5

    StyledText {
        text: root.usePercentTooltip ? `${Math.round((root.value - root.from) / Math.max(0.0001, root.to - root.from) * 100)}%`
            : (Math.round(root.value * 100) / 100).toString()
        font.pixelSize: Appearance.font.pixelSize.small
        color: Appearance.colors.colSubtext
    }
    StyledSlider {
        id: slider
        Layout.preferredWidth: 240
        from: root.from
        to: root.to
        stepSize: root.stepSize
        value: root.value
        stopIndicatorValues: root.stopIndicatorValues
        onMoved: {
            root.value = slider.value;
            root.moved();
        }
    }
}
