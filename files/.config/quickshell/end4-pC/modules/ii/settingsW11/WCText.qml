import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// Phoenix (2026-10-15): illogical-impulse's ConfigTextArea in the Windows-style look. Same API: text, description,
// buttonIcon, placeholderText, value (typing sets it, so the page's onValueChanged saves it), textArea, multiline.
WCard {
    id: root
    property string text: ""
    property string buttonIcon: ""
    property string placeholderText: ""
    property string value: ""
    property bool multiline: false
    property real fieldWidth: 220
    property real fieldHeight: 40
    property bool filled: true
    property bool rounded: false
    readonly property alias textArea: field
    signal confirmClicked()                 // ConfigTextArea compatibility: Enter in a one-line field

    title: root.text
    icon: root.buttonIcon
    opacity: enabled ? 1 : 0.5

    Rectangle {
        Layout.preferredWidth: root.multiline ? Math.max(root.fieldWidth, 320) : root.fieldWidth
        Layout.preferredHeight: root.multiline ? Math.max(root.fieldHeight, 120) : 36
        radius: 12
        color: Appearance.colors.colLayer1
        border.width: 1
        border.color: field.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
        clip: true
        Flickable {
            id: flick
            anchors.fill: parent
            anchors.margins: 8
            contentWidth: width
            contentHeight: field.implicitHeight
            clip: true
            interactive: root.multiline
            TextEdit {
                id: field
                width: flick.width
                text: root.value
                wrapMode: root.multiline ? TextEdit.Wrap : TextEdit.NoWrap
                color: Appearance.colors.colOnLayer1
                selectionColor: Appearance.colors.colPrimary
                selectedTextColor: Appearance.colors.colOnPrimary
                font.family: Appearance.font.family.main
                font.pixelSize: Appearance.font.pixelSize.small
                selectByMouse: true
                onTextChanged: if (root.value !== text) root.value = text
                Keys.onReturnPressed: event => {
                    if (root.multiline) { event.accepted = false; return; }
                    root.confirmClicked();
                    field.focus = false;
                }
            }
            StyledText {
                visible: field.text.length === 0
                text: root.placeholderText
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
            }
        }
    }
}
