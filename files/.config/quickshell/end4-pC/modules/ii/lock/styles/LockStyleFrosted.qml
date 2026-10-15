import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// Lock screen style "Frosted card" (Phoenix 2026-10-15): everything in one centered glass card in illogical-impulse's
// colors and Readex Pro; what's playing sits in a small card in the corner.
LockStyleBase {
    id: root
    passwordField: field
    readonly property string fontName: Appearance.font.family.reading

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 420 * root.s
        height: cardColumn.implicitHeight + 60 * root.s
        radius: 32 * root.s
        color: ColorUtils.transparentize(Appearance.colors.colLayer1, 0.45)
        border.width: Math.max(1, root.s)
        border.color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.82)

        Column {
            id: cardColumn
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 36 * root.s
            width: parent.width - 72 * root.s
            spacing: 18 * root.s

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 2 * root.s
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.timeText
                    color: Appearance.colors.colOnLayer1
                    font.family: root.fontName
                    font.pixelSize: 72 * root.s
                    font.weight: Font.Light
                }
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.dateText
                    color: Appearance.colors.colSubtext
                    font.family: root.fontName
                    font.pixelSize: 16 * root.s
                }
            }
            Rectangle {
                width: parent.width
                height: Math.max(1, root.s)
                color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.86)
            }
            UserAvatar {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 88 * root.s
                height: 88 * root.s
                iconSize: 52 * root.s
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.username
                color: Appearance.colors.colOnLayer1
                font.family: root.fontName
                font.pixelSize: 22 * root.s
                font.weight: Font.Medium
            }
            Row {
                width: parent.width
                spacing: 8 * root.s
                Rectangle {
                    width: parent.width - 56 * root.s
                    height: 48 * root.s
                    radius: 16 * root.s
                    color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.4)
                    border.width: Math.max(1, root.s)
                    border.color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.84)
                    LockPasswordInput {
                        id: field
                        anchors.fill: parent
                        anchors.leftMargin: 18 * root.s
                        anchors.rightMargin: 18 * root.s
                        context: root.context
                        ctrlHeld: root.ctrlHeld
                        preview: root.preview
                        fontFamily: root.fontName
                        fontSize: 15 * root.s
                    }
                }
                LockIconButton {
                    size: 48 * root.s
                    iconSize: 22 * root.s
                    buttonRadius: 16 * root.s
                    symbol: "arrow_forward"
                    iconColor: Appearance.colors.colOnPrimary
                    colBackground: Appearance.colors.colPrimary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                    enabled: !root.context.unlockInProgress
                    onClicked: root.tryUnlock()
                }
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6 * root.s
                LockIconButton { size: 44 * root.s; iconSize: 18 * root.s; symbol: "dark_mode"; colBackground: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.92); onClicked: root.sleep() }
                LockIconButton { size: 44 * root.s; iconSize: 18 * root.s; symbol: "restart_alt"; colBackground: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.92); toggled: root.context.targetAction === root.actionReboot; onClicked: root.power(root.actionReboot) }
                LockIconButton { size: 44 * root.s; iconSize: 18 * root.s; symbol: "power_settings_new"; colBackground: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.92); toggled: root.context.targetAction === root.actionPoweroff; onClicked: root.power(root.actionPoweroff) }
            }
        }
    }

    LockMediaCard {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 30 * root.s
        lock: root
        fontFamily: root.fontName
    }
}
