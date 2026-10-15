import QtQuick
import QtQuick.Layouts

// Phoenix (2026-10-15): illogical-impulse's GroupedList / ConfigRow in the Windows-style pages: the cards just stack.
ColumnLayout {
    id: root
    property bool uniform: false            // ConfigRow compatibility
    property real itemVerticalPadding: 0    // GroupedList compatibility
    property color bgcolor: "transparent"   // GroupedList compatibility
    Layout.fillWidth: true
    spacing: 4
}
