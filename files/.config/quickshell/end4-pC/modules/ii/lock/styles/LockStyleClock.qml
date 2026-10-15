import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// Lock screen style "Just the clock" (Phoenix 2026-10-15): time, date, one pill password field; power options behind
// one button in the corner.
LockStyleBase {
    id: root
    passwordField: field
    property bool powerOpen: false

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 200 * root.s
        spacing: 6 * root.s

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.timeText
            color: root.colText
            font.family: Appearance.font.family.main
            font.pixelSize: 120 * root.s
            font.weight: Font.Light
        }
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.dateText
            color: root.colTextDim
            font.pixelSize: 20 * root.s
        }
        Item { width: 1; height: 50 * root.s }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 280 * root.s
            height: 44 * root.s
            radius: height / 2
            color: ColorUtils.transparentize(Appearance.colors.colLayer1, 0.35)
            LockPasswordInput {
                id: field
                anchors.fill: parent
                anchors.leftMargin: 20 * root.s
                anchors.rightMargin: 20 * root.s
                context: root.context
                ctrlHeld: root.ctrlHeld
                preview: root.preview
                horizontalAlignment: TextInput.AlignHCenter
                fontSize: 15 * root.s
            }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 28 * root.s
        spacing: 4 * root.s
        LockIconButton { visible: root.powerOpen; size: 44 * root.s; iconSize: 20 * root.s; symbol: "dark_mode"; iconColor: root.colText; onClicked: root.sleep() }
        LockIconButton { visible: root.powerOpen; size: 44 * root.s; iconSize: 20 * root.s; symbol: "restart_alt"; iconColor: root.colText; toggled: root.context.targetAction === root.actionReboot; onClicked: root.power(root.actionReboot) }
        LockIconButton { visible: root.powerOpen; size: 44 * root.s; iconSize: 20 * root.s; symbol: "power_settings_new"; iconColor: root.colText; toggled: root.context.targetAction === root.actionPoweroff; onClicked: root.power(root.actionPoweroff) }
        LockIconButton { size: 44 * root.s; iconSize: 20 * root.s; symbol: root.powerOpen ? "close" : "power_settings_new"; iconColor: root.colTextDim; onClicked: root.powerOpen = !root.powerOpen }
    }
}
