import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// Lock screen style "Windows Hello" (Phoenix 2026-10-15): like Windows 11's sign-in screen, matching the rest of
// Phoenix: a big round picture, your name, a slim password box; the time bottom-left, power bottom-right.
LockStyleBase {
    id: root
    passwordField: field
    property bool powerOpen: false

    Rectangle {
        anchors.fill: parent
        color: ColorUtils.transparentize("#000000", 0.6)
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 150 * root.s
        spacing: 16 * root.s

        UserAvatar {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 176 * root.s
            height: 176 * root.s
            iconSize: 110 * root.s
        }
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.username
            color: "#FFFFFF"
            font.pixelSize: 30 * root.s
            font.weight: Font.Medium
            bottomPadding: 6 * root.s
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 296 * root.s
            height: 40 * root.s
            radius: 4 * root.s
            color: ColorUtils.transparentize("#FFFFFF", 0.92)
            border.width: Math.max(1, root.s)
            border.color: ColorUtils.transparentize("#FFFFFF", 0.86)
            LockPasswordInput {
                id: field
                anchors.left: parent.left
                anchors.right: goButton.left
                anchors.leftMargin: 12 * root.s
                anchors.rightMargin: 8 * root.s
                anchors.verticalCenter: parent.verticalCenter
                context: root.context
                ctrlHeld: root.ctrlHeld
                preview: root.preview
                fontSize: 15 * root.s
                textColor: "#FFFFFF"
                placeholderColor: ColorUtils.transparentize("#FFFFFF", 0.35)
            }
            LockIconButton {
                id: goButton
                anchors.right: parent.right
                anchors.rightMargin: 3 * root.s
                anchors.verticalCenter: parent.verticalCenter
                size: 32 * root.s
                implicitWidth: 34 * root.s
                iconSize: 18 * root.s
                buttonRadius: 4 * root.s
                symbol: "arrow_forward"
                iconColor: Appearance.colors.colOnPrimary
                colBackground: Appearance.colors.colPrimary
                colBackgroundHover: Appearance.colors.colPrimaryHover
                enabled: !root.context.unlockInProgress
                onClicked: root.tryUnlock()
            }
            Rectangle {   // Windows' accent line under the box
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 2 * root.s
                color: Appearance.colors.colPrimary
            }
        }
    }

    Column {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 40 * root.s
        anchors.bottomMargin: 36 * root.s
        spacing: 2 * root.s
        StyledText {
            text: root.timeText
            color: "#FFFFFF"
            font.pixelSize: 56 * root.s
            font.weight: Font.Light
        }
        StyledText {
            text: root.dateText
            color: ColorUtils.transparentize("#FFFFFF", 0.12)
            font.pixelSize: 18 * root.s
        }
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 32 * root.s
        spacing: 4 * root.s
        LockIconButton { visible: root.powerOpen; size: 44 * root.s; iconSize: 20 * root.s; buttonRadius: 6 * root.s; label: "Sleep"; iconColor: "#FFFFFF"; onClicked: root.sleep() }
        LockIconButton { visible: root.powerOpen; size: 44 * root.s; iconSize: 20 * root.s; buttonRadius: 6 * root.s; label: "Restart"; iconColor: "#FFFFFF"; toggled: root.context.targetAction === root.actionReboot; onClicked: root.power(root.actionReboot) }
        LockIconButton { visible: root.powerOpen; size: 44 * root.s; iconSize: 20 * root.s; buttonRadius: 6 * root.s; label: "Shut down"; iconColor: "#FFFFFF"; toggled: root.context.targetAction === root.actionPoweroff; onClicked: root.power(root.actionPoweroff) }
        LockIconButton { size: 44 * root.s; iconSize: 20 * root.s; buttonRadius: 6 * root.s; symbol: root.powerOpen ? "close" : "power_settings_new"; iconColor: "#FFFFFF"; onClicked: root.powerOpen = !root.powerOpen }
    }
}
