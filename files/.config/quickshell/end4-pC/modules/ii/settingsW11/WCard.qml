import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// One settings row: icon, title + description, control on the right.
// Clickable cards (links, toggles) get a hover state; `chevron` adds the "go to page" arrow.
// Phoenix (2026-10-15, "Material rail" look): cards that sit right after each other form one grouped list, with big
// corners at the two ends and small ones in between; the icon sits in a tinted rounded square.
Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string description: ""
    property string keywords: ""            // extra search words (Settings search only, not shown)
    property bool clickable: false
    property bool chevron: false
    property string chevronIcon: "chevron_right"
    property real minHeight: 64
    property real iconSize: 20
    property Component leading: null          // optional custom left item (app icon, avatar…)
    property bool grouped: true               // false: stands alone with all-round corners (notices)
    default property alias control: controlRow.data
    signal clicked()

    readonly property bool isWCard: true
    // neighbours in the same column (skipping zero-size helpers such as a Repeater). A card made by a Loader is
    // compared with the Loader's siblings, so cards from a Repeater of Loaders group too (Quick Start, setup wizard).
    function neighbour(step) {
        const self = root.parent && root.parent.sourceComponent !== undefined ? root.parent : root;
        const list = self.parent ? self.parent.visibleChildren : [];
        let i = -1;
        for (let k = 0; k < list.length; k++) if (list[k] === self) { i = k; break; }
        if (i < 0) return null;
        for (let k = i + step; k >= 0 && k < list.length; k += step) {
            const c = list[k];
            if (c.width === 0 && c.height === 0) continue;
            return c.sourceComponent !== undefined && c.item ? c.item : c;
        }
        return null;
    }
    readonly property bool groupTop: !grouped || !(neighbour(-1)?.isWCard && neighbour(-1)?.grouped)
    readonly property bool groupBottom: !grouped || !(neighbour(1)?.isWCard && neighbour(1)?.grouped)
    readonly property real bigRadius: Appearance.rounding.large
    readonly property real smallRadius: 6

    Layout.fillWidth: true
    implicitHeight: Math.max(minHeight, contentRow.implicitHeight + 28)
    topLeftRadius: groupTop ? bigRadius : smallRadius
    topRightRadius: groupTop ? bigRadius : smallRadius
    bottomLeftRadius: groupBottom ? bigRadius : smallRadius
    bottomRightRadius: groupBottom ? bigRadius : smallRadius
    color: mouse.pressed && clickable ? Appearance.colors.colLayer3Active
        : mouse.containsMouse && clickable ? Appearance.colors.colLayer3Hover
        : Appearance.colors.colLayer3
    opacity: enabled ? 1 : 0.5

    Behavior on color {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }

    // Search result (2026-10-16): the setting the search opened scrolls into view and flashes (WState.highlight)
    readonly property bool searchHit: root.title !== "" && WState.highlight === root.title && root.visible
    onSearchHitChanged: if (searchHit) hitTimer.restart()
    Component.onCompleted: if (searchHit) hitTimer.restart()
    Timer {
        id: hitTimer
        interval: 250   // after the page has laid itself out
        onTriggered: {
            let f = root.parent;
            while (f && !(f.contentY !== undefined && f.contentItem !== undefined)) f = f.parent;
            if (f) {
                const y = root.mapToItem(f.contentItem, 0, 0).y;
                f.contentY = Math.max(0, Math.min(y - f.height / 3, f.contentHeight - f.height));
            }
            flash.restart();
            WState.highlight = "";
        }
    }
    Rectangle {
        id: hitRing
        anchors.fill: parent
        z: 10
        color: "transparent"
        radius: root.topLeftRadius
        border.width: 2
        border.color: Appearance.colors.colPrimary
        opacity: 0
        SequentialAnimation {
            id: flash
            NumberAnimation { target: hitRing; property: "opacity"; to: 1; duration: 150 }
            PauseAnimation { duration: 1200 }
            NumberAnimation { target: hitRing; property: "opacity"; to: 0; duration: 600 }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: root.clickable
        enabled: root.clickable
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }

    RowLayout {
        id: contentRow
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 16
            rightMargin: 18
        }
        spacing: 16

        Loader {
            visible: root.icon.length > 0 || root.leading !== null
            active: visible
            Layout.alignment: Qt.AlignVCenter
            sourceComponent: root.leading ?? defaultIcon
        }
        Component {
            id: defaultIcon
            Rectangle {
                implicitWidth: 40
                implicitHeight: 40
                radius: 12
                color: Appearance.colors.colSecondaryContainer
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: root.icon
                    iconSize: root.iconSize
                    color: Appearance.colors.colOnSecondaryContainer
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2
            StyledText {
                Layout.fillWidth: true
                text: root.title
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer2
                elide: Text.ElideRight
            }
            StyledText {
                Layout.fillWidth: true
                visible: root.description.length > 0
                text: root.description
                font.pixelSize: Appearance.font.pixelSize.smallie
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }
        }

        RowLayout {
            id: controlRow
            Layout.alignment: Qt.AlignVCenter
            spacing: 10
        }

        MaterialSymbol {
            visible: root.chevron
            Layout.alignment: Qt.AlignVCenter
            text: root.chevronIcon
            iconSize: 20
            color: Appearance.colors.colSubtext
        }
    }
}
