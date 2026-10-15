import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// Lock screen style "Split editorial" (Phoenix 2026-10-15): a solid panel on the left with the time stacked huge, a
// minimal underlined password field and text buttons; the wallpaper on the right with what's playing.
LockStyleBase {
    id: root
    passwordField: field
    readonly property color colDim: Appearance.colors.colSubtext

    Rectangle {
        id: panel
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 500 * root.s
        color: ColorUtils.mix(Appearance.colors.colLayer0, "#000000", 0.75)

        Row {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 56 * root.s
            anchors.topMargin: 48 * root.s
            spacing: 10 * root.s
            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                text: "lock"
                iconSize: 16 * root.s
                color: root.colDim
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: `${Translation.tr("Locked")} · ${Qt.locale().toString(DateTime.clock.date, "dddd d MMMM")}`.toUpperCase()
                color: root.colDim
                font.pixelSize: 13 * root.s
                font.letterSpacing: 3 * root.s
            }
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 52 * root.s
            anchors.top: parent.top
            anchors.topMargin: 96 * root.s
            spacing: 0
            StyledText {
                text: root.hourText
                color: Appearance.colors.colOnLayer0
                font.family: Appearance.font.family.expressive
                font.pixelSize: 210 * root.s
                font.weight: Font.Bold
                font.letterSpacing: -10 * root.s
                height: 178 * root.s                    // the font's own line box is much taller than the digits
                verticalAlignment: Text.AlignVCenter
            }
            StyledText {
                text: root.minuteText
                color: Appearance.colors.colPrimary
                font.family: Appearance.font.family.expressive
                font.pixelSize: 210 * root.s
                font.weight: Font.Bold
                font.letterSpacing: -10 * root.s
                height: 178 * root.s                    // the font's own line box is much taller than the digits
                verticalAlignment: Text.AlignVCenter
            }
        }

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 56 * root.s
            anchors.rightMargin: 56 * root.s
            anchors.bottomMargin: 48 * root.s
            spacing: 14 * root.s

            StyledText {
                text: Translation.tr("Welcome back, %1").arg(root.username)
                color: root.colDim
                font.pixelSize: 15 * root.s
            }
            Row {
                width: parent.width
                spacing: 14 * root.s
                Column {
                    width: parent.width - 62 * root.s
                    spacing: 6 * root.s
                    StyledText {
                        text: Translation.tr("Password").toUpperCase()
                        color: root.colDim
                        font.pixelSize: 12 * root.s
                        font.letterSpacing: 2 * root.s
                    }
                    Item {
                        width: parent.width
                        height: 40 * root.s
                        LockPasswordInput {
                            id: field
                            anchors.fill: parent
                            context: root.context
                            ctrlHeld: root.ctrlHeld
                            preview: root.preview
                            fontSize: 22 * root.s
                            letterSpacing: 6 * root.s
                            placeholder: ""
                            textColor: Appearance.colors.colOnLayer0
                        }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 2 * root.s
                            color: Appearance.colors.colPrimary
                        }
                    }
                }
                LockIconButton {
                    anchors.bottom: parent.bottom
                    size: 48 * root.s
                    iconSize: 22 * root.s
                    symbol: "arrow_forward"
                    iconColor: Appearance.colors.colOnPrimary
                    colBackground: Appearance.colors.colPrimary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                    enabled: !root.context.unlockInProgress
                    onClicked: root.tryUnlock()
                }
            }
            Row {
                spacing: 6 * root.s
                topPadding: 6 * root.s
                LockIconButton { size: 32 * root.s; label: Translation.tr("Sleep").toUpperCase(); iconColor: root.colDim; onClicked: root.sleep() }
                LockIconButton { size: 32 * root.s; label: Translation.tr("Restart").toUpperCase(); iconColor: root.colDim; toggled: root.context.targetAction === root.actionReboot; onClicked: root.power(root.actionReboot) }
                LockIconButton { size: 32 * root.s; label: Translation.tr("Shut down").toUpperCase(); iconColor: root.colDim; toggled: root.context.targetAction === root.actionPoweroff; onClicked: root.power(root.actionPoweroff) }
            }
        }
    }

    LockMediaCard {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 32 * root.s
        lock: root
        caption: Translation.tr("Now playing").toUpperCase()
    }
}
