import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Super+/ shortcut sheet (Phoenix P15, 2026-10-16; the stock shortcut pointed at a sheet this shell no longer had):
// every shortcut Hyprland has now, including your own changes (scripts/hyprland/shortcuts.py), searchable, with a
// button to the editor in Settings. Esc, Super+/ again or a click outside the cards closes it.
Scope {
    id: root
    property bool open: false
    property var rows: []
    property string query: ""
    readonly property var groups: {
        const q = root.query.trim().toLowerCase();
        const out = [];
        for (const r of root.rows) {
            if (r.off) continue;
            if (q && !`${r.what} ${r.category} ${r.keys}`.toLowerCase().includes(q)) continue;
            let g = out.find(x => x.name === r.category);
            if (!g) { g = { name: r.category === "Yours" ? "Your own" : r.category, key: r.category, rows: [] }; out.push(g); }
            g.rows.push(r);
        }
        return out;
    }
    function toggle() {
        root.open = !root.open;
        if (root.open) { root.query = ""; listProc.running = true; }
    }
    Process {
        id: listProc
        command: ["python3", Quickshell.shellPath("scripts/hyprland/shortcuts.py"), "list"]
        stdout: StdioCollector { onStreamFinished: { try { root.rows = JSON.parse(text).rows ?? [] } catch (e) {} } }
    }
    CompositorGlobalShortcut {
        name: "cheatsheetToggle"
        description: "Shortcut sheet"
        onPressed: root.toggle()
    }
    IpcHandler {
        target: "cheatsheet"
        function toggle(): void { root.toggle() }
        function close(): void { root.open = false }
    }

    Loader {
        active: root.open
        sourceComponent: PanelWindow {
            id: win
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:cheatsheet"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            Rectangle { anchors.fill: parent; color: "black"; opacity: 0.82 }
            MouseArea { anchors.fill: parent; onClicked: root.open = false }

            Item {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: root.open = false
                Keys.onPressed: e => {
                    // typing filters right away
                    if (e.text && e.text.length === 1 && e.text.charCodeAt(0) >= 0x20 && !filter.activeFocus) {
                        filter.forceActiveFocus(); filter.text += e.text; e.accepted = true;
                    }
                }

                ColumnLayout {
                    anchors { fill: parent; margins: 48 }
                    spacing: 18
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        StyledText {
                            Layout.fillWidth: true
                            text: Translation.tr("Keyboard shortcuts")
                            font.pixelSize: Appearance.font.pixelSize.huge * 1.3
                            color: "white"
                        }
                        Rectangle {
                            implicitWidth: 340; implicitHeight: 42
                            radius: 21
                            color: Appearance.m3colors.m3surfaceContainerHigh
                            MouseArea { anchors.fill: parent; onClicked: filter.forceActiveFocus() }
                            RowLayout {
                                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                                spacing: 8
                                MaterialSymbol { text: "search"; iconSize: Appearance.font.pixelSize.larger; color: Appearance.colors.colSubtext }
                                TextField {
                                    id: filter
                                    Layout.fillWidth: true
                                    background: null
                                    placeholderText: Translation.tr("Type to filter")
                                    placeholderTextColor: Appearance.colors.colSubtext
                                    color: Appearance.colors.colOnLayer2
                                    font.family: Appearance.font.family.main
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    onTextChanged: root.query = text
                                    Keys.onEscapePressed: root.open = false
                                }
                            }
                        }
                        RippleButton {
                            implicitHeight: 42
                            horizontalPadding: 16
                            buttonRadius: 21
                            colBackground: Appearance.colors.colPrimary
                            colBackgroundHover: Appearance.colors.colPrimaryHover
                            onClicked: {
                                root.open = false;
                                Quickshell.execDetached([`${Quickshell.env("HOME")}/.local/bin/phoenix-open`, "settings", "devices", "shortcuts"]);
                            }
                            contentItem: RowLayout {
                                spacing: 6
                                MaterialSymbol { text: "edit"; iconSize: Appearance.font.pixelSize.larger; color: Appearance.colors.colOnPrimary }
                                StyledText { text: Translation.tr("Edit in Settings"); font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colOnPrimary }
                            }
                        }
                    }
                    StyledFlickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: cards.implicitHeight
                        clip: true
                        Flow {
                            id: cards
                            width: parent.width
                            spacing: 16
                            Repeater {
                                model: root.groups
                                Rectangle {
                                    id: card
                                    required property var modelData
                                    width: Math.max(320, (cards.width - 2 * 16) / 3)
                                    height: col.implicitHeight + 32
                                    radius: Appearance.rounding.large
                                    color: Appearance.m3colors.m3surfaceContainerLow   // solid: readable over any window
                                    MouseArea { anchors.fill: parent }   // clicks on a card don't close the sheet
                                    ColumnLayout {
                                        id: col
                                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                                        spacing: 6
                                        StyledText {
                                            text: card.modelData.name
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            font.weight: Font.DemiBold
                                            color: Appearance.colors.colSubtext
                                        }
                                        Repeater {
                                            model: card.modelData.rows
                                            RowLayout {
                                                id: line
                                                required property var modelData
                                                Layout.fillWidth: true
                                                spacing: 10
                                                StyledText {
                                                    Layout.fillWidth: true
                                                    text: line.modelData.what
                                                    elide: Text.ElideRight
                                                    font.pixelSize: Appearance.font.pixelSize.small
                                                    color: Appearance.colors.colOnLayer1
                                                }
                                                Rectangle {
                                                    implicitWidth: kt.implicitWidth + 14
                                                    implicitHeight: 24
                                                    radius: 7
                                                    color: line.modelData.changed ? Appearance.m3colors.m3secondaryContainer : Appearance.m3colors.m3surfaceContainerHighest
                                                    StyledText {
                                                        id: kt
                                                        anchors.centerIn: parent
                                                        text: line.modelData.keys
                                                        font.family: Appearance.font.family.monospace
                                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                                        color: Appearance.colors.colOnLayer3
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
