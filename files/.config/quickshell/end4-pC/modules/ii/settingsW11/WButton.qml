import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// Push button, Material style (2026-10-15): a tonal pill, or filled with the theme's primary color when `accent`.
RippleButton {
    id: root
    property bool accent: false
    property string iconName: ""

    implicitHeight: 40
    implicitWidth: Math.max(90, row.implicitWidth + 40)
    buttonRadius: height / 2
    colBackground: accent ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
    colBackgroundHover: accent ? Appearance.colors.colPrimaryHover : Appearance.colors.colSecondaryContainerHover
    colRipple: accent ? Appearance.colors.colPrimaryActive : Appearance.colors.colSecondaryContainerActive

    contentItem: Item {
        implicitWidth: row.implicitWidth
        implicitHeight: row.implicitHeight
        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 6
            MaterialSymbol {
                visible: root.iconName.length > 0
                text: root.iconName
                iconSize: 18
                color: root.accent ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
            }
            StyledText {
                text: root.buttonText
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Medium
                color: root.accent ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
            }
        }
    }
}
