import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// Phoenix (2026-10-15): illogical-impulse's ContentSubsection in the Windows-style look (title, tooltip, children).
ColumnLayout {
    id: root
    property string title: ""
    property string tooltip: ""
    default property alias data: subContent.data

    Layout.fillWidth: true
    spacing: 4

    StyledText {
        visible: root.title.length > 0
        Layout.topMargin: 6
        Layout.leftMargin: 6
        text: root.title
        font.pixelSize: Appearance.font.pixelSize.smaller
        font.weight: Font.Medium
        color: Appearance.colors.colSubtext
    }
    StyledText {
        visible: root.tooltip.length > 0
        Layout.fillWidth: true
        Layout.leftMargin: 6
        text: root.tooltip
        wrapMode: Text.Wrap
        font.pixelSize: Appearance.font.pixelSize.smaller
        color: Appearance.colors.colSubtext
    }
    ColumnLayout {
        id: subContent
        Layout.fillWidth: true
        spacing: 4
    }
}
