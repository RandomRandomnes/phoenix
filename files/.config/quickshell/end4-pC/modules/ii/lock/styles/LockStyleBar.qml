import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// Lock screen style "One bar at the bottom" (Phoenix 2026-10-15): the wallpaper fills the screen; time, password and
// power buttons sit in one bar along the bottom.
LockStyleBase {
    id: root
    passwordField: field

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 88 * root.s
        color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.12)

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 32 * root.s
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14 * root.s
            StyledText {
                anchors.baseline: dateLine.baseline
                text: root.timeText
                color: Appearance.colors.colOnLayer0
                font.family: Appearance.font.family.expressive
                font.pixelSize: 34 * root.s
                font.weight: Font.Medium
            }
            StyledText {
                id: dateLine
                anchors.verticalCenter: parent.verticalCenter
                text: root.dateText
                color: Appearance.colors.colSubtext
                font.pixelSize: 15 * root.s
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 8 * root.s
            Rectangle {
                width: 300 * root.s
                height: 44 * root.s
                radius: height / 2
                color: Appearance.colors.colLayer1
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 16 * root.s
                    anchors.rightMargin: 16 * root.s
                    spacing: 10 * root.s
                    StyledText {
                        id: nameLabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.username
                        color: Appearance.colors.colSubtext
                        font.pixelSize: 14 * root.s
                    }
                    LockPasswordInput {
                        id: field
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - nameLabel.width - parent.spacing
                        context: root.context
                        ctrlHeld: root.ctrlHeld
                        preview: root.preview
                        fontSize: 15 * root.s
                    }
                }
            }
            LockIconButton {
                size: 44 * root.s
                iconSize: 20 * root.s
                symbol: "arrow_forward"
                iconColor: Appearance.colors.colOnPrimary
                colBackground: Appearance.colors.colPrimary
                colBackgroundHover: Appearance.colors.colPrimaryHover
                enabled: !root.context.unlockInProgress
                onClicked: root.tryUnlock()
            }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 32 * root.s
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4 * root.s
            LockIconButton { size: 44 * root.s; iconSize: 20 * root.s; symbol: "dark_mode"; iconColor: Appearance.colors.colOnLayer0; onClicked: root.sleep() }
            LockIconButton { size: 44 * root.s; iconSize: 20 * root.s; symbol: "restart_alt"; iconColor: Appearance.colors.colOnLayer0; toggled: root.context.targetAction === root.actionReboot; onClicked: root.power(root.actionReboot) }
            LockIconButton { size: 44 * root.s; iconSize: 20 * root.s; symbol: "power_settings_new"; iconColor: Appearance.colors.colOnLayer0; toggled: root.context.targetAction === root.actionPoweroff; onClicked: root.power(root.actionPoweroff) }
        }
    }
}
