import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// A titled group of cards; the cards join into one grouped list (WCard).
ColumnLayout {
    id: root
    property string title: ""
    default property alias cards: cardColumn.data

    Layout.fillWidth: true
    spacing: 8

    StyledText {
        visible: root.title.length > 0
        Layout.topMargin: 6
        Layout.leftMargin: 6
        text: root.title
        font.pixelSize: Appearance.font.pixelSize.small
        font.weight: Font.Medium
        color: Appearance.colors.colSubtext
    }

    ColumnLayout {
        id: cardColumn
        Layout.fillWidth: true
        spacing: 4
    }
}
