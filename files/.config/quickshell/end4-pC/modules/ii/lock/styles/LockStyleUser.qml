import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// Lock screen style "You and a password" (Phoenix 2026-10-15): your picture, your name and the field in the middle;
// the time as one small line at the top.
LockStyleBase {
    id: root
    passwordField: field

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 28 * root.s
        text: `${root.timeText}  ·  ${root.dateText}`
        color: root.colTextDim
        font.pixelSize: 16 * root.s
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 230 * root.s
        spacing: 14 * root.s

        UserAvatar {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 96 * root.s
            height: 96 * root.s
            iconSize: 56 * root.s
        }
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.username
            color: root.colText
            font.pixelSize: 22 * root.s
            font.weight: Font.Medium
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8 * root.s
            topPadding: 8 * root.s
            Rectangle {
                width: 260 * root.s
                height: 44 * root.s
                radius: 12 * root.s
                color: ColorUtils.transparentize(Appearance.colors.colLayer1, 0.35)
                LockPasswordInput {
                    id: field
                    anchors.fill: parent
                    anchors.leftMargin: 18 * root.s
                    anchors.rightMargin: 18 * root.s
                    context: root.context
                    ctrlHeld: root.ctrlHeld
                    preview: root.preview
                    fontSize: 15 * root.s
                }
            }
            LockIconButton {
                size: 44 * root.s
                iconSize: 22 * root.s
                buttonRadius: 12 * root.s
                symbol: "arrow_forward"
                iconColor: Appearance.colors.colOnPrimary
                colBackground: Appearance.colors.colPrimary
                colBackgroundHover: Appearance.colors.colPrimaryHover
                enabled: !root.context.unlockInProgress
                onClicked: root.tryUnlock()
            }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 28 * root.s
        spacing: 4 * root.s
        LockIconButton { size: 44 * root.s; iconSize: 20 * root.s; symbol: "dark_mode"; iconColor: root.colTextDim; onClicked: root.sleep() }
        LockIconButton { size: 44 * root.s; iconSize: 20 * root.s; symbol: "restart_alt"; iconColor: root.colTextDim; toggled: root.context.targetAction === root.actionReboot; onClicked: root.power(root.actionReboot) }
        LockIconButton { size: 44 * root.s; iconSize: 20 * root.s; symbol: "power_settings_new"; iconColor: root.colTextDim; toggled: root.context.targetAction === root.actionPoweroff; onClicked: root.power(root.actionPoweroff) }
    }
}
