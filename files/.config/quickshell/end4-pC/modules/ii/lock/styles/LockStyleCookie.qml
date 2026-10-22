import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// Lock screen style "Cookie clock" (Phoenix 2026-10-15): illogical-impulse's scalloped cookie as an analog clock on the
// left; the date, your picture in a clover shape and a bold password field on the right.
LockStyleBase {
    id: root
    passwordField: field
    readonly property real clockSize: 340 * root.s
    readonly property int hours: DateTime.clock.date.getHours()
    readonly property int minutes: DateTime.clock.date.getMinutes()

    // the clock
    Item {
        x: 170 * root.s
        y: (root.height - root.clockSize) / 2
        width: root.clockSize
        height: root.clockSize

        MaterialShape {
            anchors.fill: parent
            shape: MaterialShape.Shape.Cookie12Sided
            color: Appearance.colors.colPrimaryContainer
        }
        Repeater {   // hour marks
            model: 12
            Rectangle {
                required property int index
                readonly property real r: root.clockSize * 0.38
                readonly property real a: (index * 30 - 90) * Math.PI / 180
                width: (index % 3 === 0 ? 12 : 7) * root.s
                height: width
                radius: width / 2
                x: root.clockSize / 2 + r * Math.cos(a) - width / 2
                y: root.clockSize / 2 + r * Math.sin(a) - height / 2
                color: ColorUtils.transparentize(Appearance.colors.colOnPrimaryContainer, 0.35)
            }
        }
        Rectangle {   // hour hand
            x: root.clockSize / 2 - height / 2
            y: root.clockSize / 2 - height / 2
            width: root.clockSize * 0.24
            height: 15 * root.s
            radius: height / 2
            transformOrigin: Item.Left
            rotation: ((root.hours % 12) + root.minutes / 60) * 30 - 90
            color: Appearance.colors.colOnPrimaryContainer
        }
        Rectangle {   // minute hand
            x: root.clockSize / 2 - height / 2
            y: root.clockSize / 2 - height / 2
            width: root.clockSize * 0.36
            height: 10 * root.s
            radius: height / 2
            transformOrigin: Item.Left
            rotation: root.minutes * 6 - 90
            color: Appearance.colors.colPrimary
        }
        Rectangle {
            anchors.centerIn: parent
            width: 18 * root.s
            height: width
            radius: width / 2
            color: Appearance.colors.colOnPrimaryContainer
        }
    }

    // date, you, password
    Column {
        x: 640 * root.s
        y: (root.height - implicitHeight) / 2
        width: 460 * root.s
        spacing: 28 * root.s

        Column {
            spacing: 2 * root.s
            StyledText {
                text: root.weekdayText
                color: root.colText
                font.family: Appearance.font.family.expressive
                font.pixelSize: 64 * root.s
                font.weight: Font.Medium
            }
            StyledText {
                text: root.dayMonthText
                color: Appearance.colors.colPrimary
                font.family: Appearance.font.family.expressive
                font.pixelSize: 64 * root.s
            }
        }

        Row {
            spacing: 16 * root.s
            Item {
                width: 64 * root.s
                height: 64 * root.s
                MaterialShape {
                    anchors.fill: parent
                    shape: MaterialShape.Shape.Clover4Leaf
                    color: Appearance.colors.colPrimaryContainer
                }
                StyledText {
                    anchors.centerIn: parent
                    text: root.username.charAt(0).toUpperCase()
                    color: Appearance.colors.colOnPrimaryContainer
                    font.pixelSize: 26 * root.s
                    font.weight: Font.Medium
                }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2 * root.s
                StyledText {
                    text: root.username
                    color: root.colText
                    font.pixelSize: 22 * root.s
                    font.weight: Font.Medium
                }
                StyledText {
                    text: root.atLogin ? Translation.tr("Type your password to sign in") : Translation.tr("Type your password to unlock")
                    color: root.colTextDim
                    font.pixelSize: 14 * root.s
                }
            }
        }

        Row {
            width: parent.width
            spacing: 10 * root.s
            Rectangle {
                width: parent.width - 82 * root.s
                height: 56 * root.s
                radius: 20 * root.s
                color: ColorUtils.transparentize(Appearance.colors.colLayer1, 0.1)
                border.width: 2 * root.s
                border.color: Appearance.colors.colPrimary
                LockPasswordInput {
                    id: field
                    anchors.fill: parent
                    anchors.leftMargin: 22 * root.s
                    anchors.rightMargin: 22 * root.s
                    context: root.context
                    ctrlHeld: root.ctrlHeld
                    preview: root.preview
                    fontSize: 16 * root.s
                }
            }
            LockIconButton {
                size: 56 * root.s
                implicitWidth: 72 * root.s
                iconSize: 24 * root.s
                buttonRadius: 20 * root.s
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
        anchors.margins: 32 * root.s
        spacing: 10 * root.s
        LockIconButton { size: 44 * root.s; iconSize: 18 * root.s; symbol: "dark_mode"; label: Translation.tr("Sleep"); colBackground: ColorUtils.transparentize(Appearance.colors.colLayer1, 0.15); onClicked: root.sleep() }
        LockIconButton { size: 44 * root.s; iconSize: 18 * root.s; symbol: "restart_alt"; label: Translation.tr("Restart"); colBackground: ColorUtils.transparentize(Appearance.colors.colLayer1, 0.15); toggled: root.context.targetAction === root.actionReboot; onClicked: root.power(root.actionReboot) }
        LockIconButton { size: 44 * root.s; iconSize: 18 * root.s; symbol: "power_settings_new"; label: Translation.tr("Shut down"); colBackground: ColorUtils.transparentize(Appearance.colors.colLayer1, 0.15); toggled: root.context.targetAction === root.actionPoweroff; onClicked: root.power(root.actionPoweroff) }
    }
}
