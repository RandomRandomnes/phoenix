import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// What's playing, as a small card for the Phoenix lock screen styles (2026-10-15). Hidden when nothing plays or when
// lock.showMedia is off.
Rectangle {
    id: root
    required property Item lock          // the LockStyleBase it belongs to
    property string fontFamily: Appearance.font.family.main
    property string caption: ""          // e.g. "NOW PLAYING" above the title
    readonly property real s: lock.s

    visible: lock.showMedia
    width: row.implicitWidth + 30 * s
    height: 60 * s
    radius: 18 * s
    color: ColorUtils.transparentize(Appearance.colors.colLayer1, 0.3)

    Row {
        id: row
        anchors.left: parent.left
        anchors.leftMargin: 10 * root.s
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12 * root.s
        Rectangle {
            width: 40 * root.s
            height: 40 * root.s
            radius: 12 * root.s
            color: Appearance.colors.colPrimaryContainer
            clip: true
            StyledImage {
                anchors.fill: parent
                source: root.lock.artUrl
                fillMode: Image.PreserveAspectCrop
                visible: root.lock.artUrl !== ""
                sourceSize.width: width * 2
                sourceSize.height: height * 2
            }
            MaterialSymbol {
                anchors.centerIn: parent
                visible: root.lock.artUrl === ""
                text: "music_note"
                iconSize: 20 * root.s
                color: Appearance.colors.colOnPrimaryContainer
            }
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2 * root.s
            StyledText {
                visible: root.caption !== ""
                text: root.caption
                color: Appearance.colors.colSubtext
                font.family: root.fontFamily
                font.pixelSize: 11 * root.s
                font.letterSpacing: 2 * root.s
            }
            StyledText {
                width: Math.min(implicitWidth, 260 * root.s)
                elide: Text.ElideRight
                text: root.lock.trackTitle
                color: Appearance.colors.colOnLayer1
                font.family: root.fontFamily
                font.pixelSize: 14 * root.s
                font.weight: Font.Medium
            }
            StyledText {
                width: Math.min(implicitWidth, 260 * root.s)
                elide: Text.ElideRight
                text: root.lock.trackArtist
                color: Appearance.colors.colSubtext
                font.family: root.fontFamily
                font.pixelSize: 12 * root.s
            }
        }
    }
}
