import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// Phoenix (2026-11-13): the pill the lock screen's "Switch to KDE Plasma" and "Switch user" use, top right (LockStyleLoader);
// the login screen's GreeterChips has the same look.
RippleButton {
    id: chip
    property string symbol: ""
    property string label: ""
    property bool warn: false        // armed / waiting for the password: error colors
    implicitHeight: 44
    implicitWidth: chipRow.implicitWidth + 36
    buttonRadius: height / 2
    colBackground: warn ? Appearance.colors.colErrorContainer : ColorUtils.transparentize(Appearance.colors.colLayer0, 0.3)
    colBackgroundHover: warn ? Appearance.colors.colErrorContainerHover : Appearance.colors.colLayer1Hover
    contentItem: Item {
        RowLayout {
            id: chipRow
            anchors.centerIn: parent
            spacing: 8
            MaterialSymbol {
                text: chip.symbol
                iconSize: 20
                color: chip.warn ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnLayer0
            }
            StyledText {
                text: chip.label
                font.pixelSize: Appearance.font.pixelSize.small
                color: chip.warn ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnLayer0
            }
        }
    }
}
