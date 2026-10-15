import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// Card with a dropdown. model: [{ displayName, value }], emits selected(value).
WCard {
    id: root
    property var model: []
    property var currentValue
    property real fieldWidth: 240
    signal selected(var value)

    StyledComboBox {
        id: combo
        Layout.fillWidth: false
        Layout.preferredWidth: root.fieldWidth
        textRole: "displayName"
        model: root.model
        currentIndex: {
            const i = root.model.findIndex(m => m.value === root.currentValue);
            return i;
        }
        displayText: currentIndex >= 0 ? root.model[currentIndex].displayName : "—"
        onActivated: index => {
            root.selected(root.model[index].value);
            // picking an entry breaks the binding above; tie it to currentValue again, so the box shows the real state
            // when the choice didn't go through (e.g. a password window closed) (2026-10-15)
            currentIndex = Qt.binding(() => root.model.findIndex(m => m.value === root.currentValue));
        }
    }
}
