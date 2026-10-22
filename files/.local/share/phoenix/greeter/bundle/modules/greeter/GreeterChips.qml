import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// Phoenix login screen (2026-10-22): what only the login screen has, over a lock screen style (top right, where the
// lock screen shows "Switch user"): one chip per account when there are several, and the desktop to start (Phoenix /
// KDE Plasma, click to switch) when KDE is installed. Same pill look as the lock screen's Switch user button.
Row {
    id: chips
    required property var greeter
    spacing: 8

    component Chip: RippleButton {
        id: chip
        property string symbol: ""
        property string label: ""
        property bool selected: false
        implicitHeight: 44
        implicitWidth: chipRow.implicitWidth + 36
        buttonRadius: height / 2
        colBackground: selected ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colLayer0, 0.3)
        colBackgroundHover: selected ? Appearance.colors.colPrimaryHover : Appearance.colors.colLayer1Hover
        contentItem: Item {
            Row {
                id: chipRow
                anchors.centerIn: parent
                spacing: 8
                MaterialSymbol {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: chip.symbol !== ""
                    text: chip.symbol
                    iconSize: 20
                    color: chip.selected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: chip.label
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: chip.selected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0
                }
            }
        }
    }

    Repeater {
        model: chips.greeter.users.length > 1 ? chips.greeter.users : []
        Chip {
            required property var modelData
            required property int index
            symbol: index === chips.greeter.userIndex ? "person" : ""
            label: modelData.real || modelData.name
            selected: index === chips.greeter.userIndex
            onClicked: chips.greeter.pickUser(index)
        }
    }
    Chip {
        visible: chips.greeter.sessions.length > 1
        symbol: "desktop_windows"
        label: chips.greeter.sessions[chips.greeter.sessionIndex]?.name ?? ""
        onClicked: chips.greeter.sessionIndex = (chips.greeter.sessionIndex + 1) % chips.greeter.sessions.length
    }
}
