import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// Phoenix (2026-10-15): illogical-impulse's ConfigSwitch in the Windows-style look. Same API: text, buttonIcon,
// checked (a click flips it, so the page's onCheckedChanged does the saving, as before).
WCard {
    id: root
    property string text: ""
    property string buttonIcon: ""
    property bool checked: false

    icon: root.buttonIcon
    title: root.text
    clickable: true
    opacity: enabled ? 1 : 0.5
    onClicked: root.checked = !root.checked

    StyledSwitch {
        checked: root.checked
        onClicked: root.checked = !root.checked
        onCheckedChanged: if (checked !== root.checked) checked = Qt.binding(() => root.checked)
    }
}
