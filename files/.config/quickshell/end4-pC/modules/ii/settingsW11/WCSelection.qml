import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// Phoenix (2026-10-15): illogical-impulse's ConfigSelectionArray in the Windows-style look, as a dropdown. Same API:
// text, icon, options [{displayName, icon, value}], currentValue, selected(newValue).
WCard {
    id: root
    property string text: ""
    property var options: []
    property var currentValue: null
    property bool textOnlyWhenActive: false   // accepted for compatibility
    property real fieldWidth: 220
    signal selected(var newValue)

    title: root.text
    opacity: enabled ? 1 : 0.5

    function indexOfCurrent() {
        // loose match like illogical-impulse's selection (a value may come back as "1" for 1)
        return root.options.findIndex(o => o.value == root.currentValue);
    }

    StyledComboBox {
        id: combo
        Layout.fillWidth: false
        Layout.preferredWidth: root.fieldWidth
        Layout.maximumWidth: root.fieldWidth
        textRole: "label"
        model: root.options.map(o => ({ label: (o.displayName || String(o.value)).replace(/^./, c => c.toUpperCase()), value: o.value }))
        currentIndex: root.indexOfCurrent()
        displayText: currentIndex >= 0 ? model[currentIndex].label : "—"
        onActivated: index => {
            root.selected(root.options[index].value);
            currentIndex = Qt.binding(() => root.indexOfCurrent());
        }
    }
}
