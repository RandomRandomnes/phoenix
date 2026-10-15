import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// Phoenix (2026-10-15): illogical-impulse's ConfigComboBox in the Windows-style look. Same API: text, description,
// buttonIcon, model [{displayName, value}], textRole, currentValue, fieldWidth, selected(newValue).
WCard {
    id: root
    property string text: ""
    property string buttonIcon: ""
    property var model: []
    property string textRole: "displayName"
    property var currentValue: undefined
    property real fieldWidth: 220
    property bool fixedWidth: false
    property bool searchable: false
    readonly property alias comboBox: combo
    signal selected(var newValue)

    title: root.text
    icon: root.buttonIcon
    opacity: enabled ? 1 : 0.5

    function indexOfCurrent() {
        return root.model.findIndex(item => item.value == root.currentValue);
    }

    StyledComboBox {
        id: combo
        Layout.fillWidth: false
        Layout.preferredWidth: root.fieldWidth
        Layout.maximumWidth: root.fieldWidth
        textRole: root.textRole
        model: root.model
        currentIndex: root.indexOfCurrent()
        displayText: currentIndex >= 0 ? (root.model[currentIndex][root.textRole] ?? "") : "—"
        onActivated: index => {
            root.selected(root.model[index].value);
            currentIndex = Qt.binding(() => root.indexOfCurrent());
        }
    }
}
