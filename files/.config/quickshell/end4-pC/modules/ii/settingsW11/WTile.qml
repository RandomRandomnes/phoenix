import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// Large Home-page tile: title, description, free content, optional footer link.
Rectangle {
    id: root
    property string title: ""
    property string description: ""
    property string linkText: ""
    signal linkClicked()
    default property alias content: body.data

    Layout.fillWidth: true
    Layout.preferredWidth: 100     // grid columns share the width evenly instead of growing to fit content
    implicitHeight: col.implicitHeight + 40
    radius: Appearance.rounding.large
    color: Appearance.colors.colLayer3

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
        spacing: 12

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true
            StyledText {
                text: root.title
                font.family: Appearance.font.family.expressive
                font.pixelSize: Appearance.font.pixelSize.larger
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer2
            }
            StyledText {
                visible: root.description.length > 0
                Layout.fillWidth: true
                text: root.description
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }
        }

        ColumnLayout {
            id: body
            Layout.fillWidth: true
            spacing: 3
        }

        StyledText {
            visible: root.linkText.length > 0
            text: root.linkText
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colPrimary
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.linkClicked()
            }
        }
    }
}
