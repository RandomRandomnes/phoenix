import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// Phoenix (2026-10-15): illogical-impulse's ContentSection in the Windows-style look, same API (title, icon, hint,
// children), so the original settings sections could move into these pages unchanged. See WCSwitch etc.
ColumnLayout {
    id: root
    property string title: ""
    property string icon: ""
    property string hint: ""
    property string hintIcon: "info"
    property bool collapsible: false        // accepted for compatibility; sections here don't collapse
    property var shape                      // accepted for compatibility
    property var bgColor                    // accepted for compatibility
    default property alias data: sectionContent.data

    Layout.fillWidth: true
    spacing: 8

    RowLayout {
        visible: root.title.length > 0
        Layout.topMargin: 10
        Layout.leftMargin: 6
        spacing: 8
        StyledText {
            text: root.title
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.Medium
            color: Appearance.colors.colSubtext
        }
    }
    StyledText {
        visible: root.hint.length > 0
        Layout.fillWidth: true
        Layout.leftMargin: 6
        text: root.hint
        wrapMode: Text.Wrap
        font.pixelSize: Appearance.font.pixelSize.smaller
        color: Appearance.colors.colSubtext
    }
    ColumnLayout {
        id: sectionContent
        Layout.fillWidth: true
        spacing: 4
    }
}
