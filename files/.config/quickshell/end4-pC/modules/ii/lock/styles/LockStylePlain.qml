import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// Lock screen style "Plain dark" (Phoenix 2026-10-15): no wallpaper; a dark background, the time in a monospace font,
// an underlined password field and sleep / restart / shut down as plain text.
LockStyleBase {
    id: root
    passwordField: field
    readonly property string mono: Appearance.font.family.monospace
    readonly property color colDim: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.4)

    Rectangle {
        anchors.fill: parent
        color: ColorUtils.mix(Appearance.colors.colLayer0, "#000000", 0.6)
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 240 * root.s
        spacing: 10 * root.s

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.timeText
            color: Appearance.colors.colOnLayer0
            font.family: root.mono
            font.pixelSize: 72 * root.s
            font.weight: Font.Light
            font.letterSpacing: 2 * root.s
        }
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.locale().toString(DateTime.clock.date, "ddd d MMM").toUpperCase()
            color: root.colDim
            font.family: root.mono
            font.pixelSize: 14 * root.s
            font.letterSpacing: 3 * root.s
        }
        Item { width: 1; height: 52 * root.s }
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: `password for ${root.username}`
            color: root.colDim
            font.family: root.mono
            font.pixelSize: 13 * root.s
        }
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 240 * root.s
            height: 36 * root.s
            LockPasswordInput {
                id: field
                anchors.fill: parent
                context: root.context
                ctrlHeld: root.ctrlHeld
                preview: root.preview
                fontFamily: root.mono
                fontSize: 18 * root.s
                letterSpacing: 6 * root.s
                horizontalAlignment: TextInput.AlignHCenter
                placeholder: ""
                passwordCharacter: "*"
                textColor: Appearance.colors.colOnLayer0
            }
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Math.max(1, root.s)
                color: root.colDim
            }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24 * root.s
        spacing: 20 * root.s
        LockIconButton { size: 36 * root.s; label: "sleep"; fontFamily: root.mono; iconColor: root.colDim; onClicked: root.sleep() }
        LockIconButton { size: 36 * root.s; label: "restart"; fontFamily: root.mono; iconColor: root.colDim; toggled: root.context.targetAction === root.actionReboot; onClicked: root.power(root.actionReboot) }
        LockIconButton { size: 36 * root.s; label: "shut down"; fontFamily: root.mono; iconColor: root.colDim; toggled: root.context.targetAction === root.actionPoweroff; onClicked: root.power(root.actionPoweroff) }
    }
}
