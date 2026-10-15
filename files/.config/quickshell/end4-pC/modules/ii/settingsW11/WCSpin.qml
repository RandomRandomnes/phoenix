import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// Phoenix (2026-10-15): illogical-impulse's ConfigSpinBox in the Windows-style look. Same API: text, icon, value,
// from, to, stepSize, valueModified() (changing it sets `value`, so the page's onValueChanged saves it, as before).
WCard {
    id: root
    property string text: ""
    property string buttonIcon: ""
    property real value: 0
    property real from: 0
    property real to: 100
    property real stepSize: 1
    signal valueModified()

    title: root.text
    icon: root.buttonIcon
    opacity: enabled ? 1 : 0.5

    StyledSpinBox {
        id: spin
        from: root.from
        to: root.to
        stepSize: root.stepSize
        value: root.value
        onValueModified: {
            root.value = spin.value;
            root.valueModified();
        }
    }
}
