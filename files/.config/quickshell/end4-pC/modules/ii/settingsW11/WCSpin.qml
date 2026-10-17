import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// Phoenix (2026-10-15): illogical-impulse's ConfigSpinBox in the Windows-style look. API: text, icon, value, from, to,
// stepSize, edited(value), valueModified(). A change is reported through edited(value) and `value` stays bound to the
// page's setting (2026-10-16: it set `value` itself, cutting the binding); only an unbound spin box sets itself.
WCard {
    id: root
    property string text: ""
    property string buttonIcon: ""
    property real value: 0
    property real from: 0
    property real to: 100
    property real stepSize: 1
    signal valueModified()
    signal edited(real value)

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
            const v = spin.value;
            root.edited(v);
            if (root.value !== v) root.value = v;
            spin.value = Qt.binding(() => root.value);   // follow the setting again after the user's change
            root.valueModified();
        }
    }
}
