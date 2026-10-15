import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// Phoenix (2026-10-15): illogical-impulse's NoticeBox in the Windows-style look (materialIcon, text, buttons as children).
WCard {
    id: root
    property string materialIcon: "info"
    property string text: ""
    icon: root.materialIcon
    description: root.text
    grouped: false
}
