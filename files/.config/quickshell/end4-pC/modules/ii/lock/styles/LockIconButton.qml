import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// Round (or rounded) icon button for the Phoenix lock screen styles (2026-10-15). With `label` set it becomes a pill
// with icon + text.
RippleButton {
    id: root
    property string symbol: ""
    property string label: ""
    property color iconColor: Appearance.colors.colOnLayer1
    property real size: 44
    property real iconSize: 22
    property string fontFamily: Appearance.font.family.main

    implicitHeight: root.size
    implicitWidth: root.label.length > 0 ? contentRow.implicitWidth + 36 : root.size
    buttonRadius: root.size / 2
    colBackground: ColorUtils.transparentize(Appearance.colors.colLayer1, 1)
    colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.88)
    colRipple: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.8)

    contentItem: Item {
        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: 8
            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.symbol.length > 0
                text: root.symbol
                iconSize: root.iconSize
                color: root.iconColor
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.label.length > 0
                text: root.label
                font.family: root.fontFamily
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.iconColor
            }
        }
    }
}
