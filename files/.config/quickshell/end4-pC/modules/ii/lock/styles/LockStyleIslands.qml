import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import ".." as LockDir

// Lock screen style "Material islands" (Phoenix 2026-10-15, concept 1): illogical-impulse's layout, refined: a big
// clock with the date and a "Locked" chip in the middle; three rounded islands along the bottom: you and what's
// playing, the password field with illogical-impulse's shape dots, and sleep / restart / shut down.
LockStyleBase {
    id: root
    passwordField: field
    readonly property real k: root.s * 0.81  // drawn smaller than the concept: 10% and then 10% again (user, 2026-10-15)
    readonly property color colIsland: ColorUtils.transparentize(Appearance.colors.colLayer1, 0.15)
    readonly property bool shapeDots: Config.options.lock.materialShapeChars

    // clock, date, "Locked"
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 150 * root.k
        spacing: 4 * root.k

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.timeText
            color: Appearance.colors.colPrimary
            font.family: Appearance.font.family.expressive
            font.pixelSize: 168 * root.k
            font.weight: Font.Medium
            font.letterSpacing: -4 * root.k
            height: 172 * root.k
            verticalAlignment: Text.AlignVCenter
        }
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.dateText
            color: root.colText
            font.pixelSize: 26 * root.k
        }
        Item { width: 1; height: 14 * root.k; visible: lockedChip.visible }
        Rectangle {
            id: lockedChip
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Config.options.lock.showLockedText
            width: lockedRow.implicitWidth + 32 * root.k
            height: 36 * root.k
            radius: height / 2
            color: ColorUtils.transparentize(Appearance.colors.colLayer1, 0.4)
            Row {
                id: lockedRow
                anchors.centerIn: parent
                spacing: 8 * root.k
                MaterialSymbol {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "lock"
                    iconSize: 16 * root.k
                    color: Appearance.colors.colSubtext
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Translation.tr("Locked")
                    color: Appearance.colors.colSubtext
                    font.pixelSize: 15 * root.k
                }
            }
        }
    }

    // the three islands
    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 32 * root.k
        height: 64 * root.k

        // you and what's playing
        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            visible: Config.options.lock.showToolbars
            width: leftRow.implicitWidth + 26 * root.k
            height: 60 * root.k
            radius: height / 2
            color: root.colIsland
            Row {
                id: leftRow
                anchors.left: parent.left
                anchors.leftMargin: 8 * root.k
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12 * root.k
                UserAvatar {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44 * root.k
                    height: 44 * root.k
                    iconSize: 28 * root.k
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.username
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: 16 * root.k
                    font.weight: Font.Medium
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.showMedia
                    width: Math.max(1, root.k)
                    height: 28 * root.k
                    color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.75)
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.showMedia
                    width: 40 * root.k
                    height: 40 * root.k
                    radius: 12 * root.k
                    color: Appearance.colors.colPrimaryContainer
                    clip: true
                    StyledImage {
                        anchors.fill: parent
                        source: root.artUrl
                        fillMode: Image.PreserveAspectCrop
                        visible: root.artUrl !== ""
                        sourceSize.width: width * 2
                        sourceSize.height: height * 2
                    }
                    MaterialSymbol {
                        anchors.centerIn: parent
                        visible: root.artUrl === ""
                        text: "music_note"
                        iconSize: 20 * root.k
                        color: Appearance.colors.colOnPrimaryContainer
                    }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.showMedia
                    spacing: 2 * root.k
                    StyledText {
                        width: Math.min(implicitWidth, 200 * root.k)
                        elide: Text.ElideRight
                        text: root.trackTitle
                        color: Appearance.colors.colOnLayer1
                        font.pixelSize: 14 * root.k
                        font.weight: Font.Medium
                    }
                    StyledText {
                        width: Math.min(implicitWidth, 200 * root.k)
                        elide: Text.ElideRight
                        text: root.trackArtist
                        color: Appearance.colors.colSubtext
                        font.pixelSize: 12 * root.k
                    }
                }
            }
        }

        // the password
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: centerRow.implicitWidth + 16 * root.k
            height: 64 * root.k
            radius: height / 2
            color: root.colIsland
            Row {
                id: centerRow
                anchors.centerIn: parent
                spacing: 8 * root.k
                Rectangle {
                    width: 340 * root.k
                    height: 48 * root.k
                    radius: height / 2
                    color: Appearance.m3colors.m3surfaceContainerHighest
                    MaterialSymbol {
                        id: lockIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 18 * root.k
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.context.fingerprintsConfigured ? "fingerprint" : "lock"
                        iconSize: 18 * root.k
                        color: Appearance.colors.colSubtext
                    }
                    LockPasswordInput {
                        id: field
                        anchors.left: lockIcon.right
                        anchors.right: parent.right
                        anchors.leftMargin: 12 * root.k
                        anchors.rightMargin: 18 * root.k
                        anchors.verticalCenter: parent.verticalCenter
                        height: 30 * root.k
                        context: root.context
                        ctrlHeld: root.ctrlHeld
                        preview: root.preview
                        fontSize: 15 * root.k
                        placeholder: Translation.tr("Enter password")
                        textColor: root.shapeDots ? "transparent" : Appearance.colors.colOnLayer1
                    }
                    Loader {   // illogical-impulse's shape dots, drawn over the (invisible) text
                        anchors.fill: field
                        active: root.shapeDots
                        sourceComponent: LockDir.PasswordChars {
                            length: root.context.currentText.length
                            selectionStart: field.textInput.selectionStart
                            selectionEnd: field.textInput.selectionEnd
                            cursorPosition: field.textInput.cursorPosition
                            charSize: 16 * root.k
                        }
                    }
                }
                LockIconButton {
                    size: 48 * root.k
                    iconSize: 22 * root.k
                    symbol: root.context.targetAction === root.actionPoweroff ? "power_settings_new"
                        : root.context.targetAction === root.actionReboot ? "restart_alt"
                        : root.ctrlHeld ? "coffee" : "arrow_forward"
                    iconColor: Appearance.colors.colOnPrimary
                    colBackground: Appearance.colors.colPrimary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                    enabled: !root.context.unlockInProgress
                    onClicked: root.tryUnlock()
                }
            }
        }

        // sleep, restart, shut down
        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: Config.options.lock.showToolbars
            width: rightRow.implicitWidth + 16 * root.k
            height: 60 * root.k
            radius: height / 2
            color: root.colIsland
            Row {
                id: rightRow
                anchors.centerIn: parent
                spacing: 4 * root.k
                LockIconButton { size: 44 * root.k; iconSize: 20 * root.k; symbol: "dark_mode"; onClicked: root.sleep() }
                LockIconButton { size: 44 * root.k; iconSize: 20 * root.k; symbol: "restart_alt"; toggled: root.context.targetAction === root.actionReboot; onClicked: root.power(root.actionReboot) }
                LockIconButton {
                    size: 44 * root.k
                    iconSize: 20 * root.k
                    symbol: "power_settings_new"
                    iconColor: Appearance.colors.colOnError
                    colBackground: Appearance.colors.colError
                    colBackgroundHover: Appearance.colors.colErrorHover
                    toggled: root.context.targetAction === root.actionPoweroff
                    onClicked: root.power(root.actionPoweroff)
                }
            }
        }
    }
}
