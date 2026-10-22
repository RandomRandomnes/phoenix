import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Settings › Bluetooth & devices › Keyboard › Shortcuts (Phoenix P15, 2026-10-16). Every shortcut Hyprland has,
// searchable and grouped; change one by pressing the new keys (a clash is shown, "Use anyway" switches the other one
// off), switch one off, reset to the default, or add your own command. Data and writing: scripts/hyprland/shortcuts.py;
// your changes live in ~/.config/hypr/custom/user-keybinds.lua (see custom/env.lua), never touched by updates.
WPage {
    id: page
    readonly property string helper: Quickshell.shellPath("scripts/hyprland/shortcuts.py")
    property var rows: []
    property string query: ""
    property string status: ""
    readonly property var shown: {
        const q = page.query.trim().toLowerCase();
        return q === "" ? page.rows : page.rows.filter(r => `${r.what} ${r.category} ${r.keys} ${r.original}`.toLowerCase().includes(q));
    }
    readonly property var groups: {
        const out = [];
        for (const r of page.shown) {
            let g = out.find(x => x.name === r.category);
            if (!g) { g = { name: r.category, rows: [] }; out.push(g); }
            g.rows.push(r);
        }
        return out;
    }
    function refresh() { listProc.running = true }
    Component.onCompleted: refresh()
    Connections { target: WState; function onRefreshTickChanged() { page.refresh() } }
    Process {
        id: listProc
        command: ["python3", page.helper, "list"]
        stdout: StdioCollector { onStreamFinished: { try { page.rows = JSON.parse(text).rows ?? [] } catch (e) {} } }
    }
    Process {
        id: writeProc
        stdout: StdioCollector {
            onStreamFinished: {
                let r = {};
                try { r = JSON.parse(text) } catch (e) {}
                if (r.conflict) { capture.conflict = `${r.category}: ${r.conflict}`; return; }
                page.status = r.errors ? `Hyprland reported: ${r.errors}` : "";
                capture.close();
                page.refresh();
            }
        }
    }
    function run(args) {
        writeProc.command = ["python3", page.helper].concat(args);
        writeProc.running = true;
    }

    // ── keys → Hyprland names ──
    function keyName(e) {
        const k = e.key;
        if (k >= Qt.Key_A && k <= Qt.Key_Z) return String.fromCharCode(k);
        if (k >= Qt.Key_0 && k <= Qt.Key_9) return String.fromCharCode(k);
        if (k >= Qt.Key_F1 && k <= Qt.Key_F24) return `F${k - Qt.Key_F1 + 1}`;
        const m = {
            [Qt.Key_Return]: "Return", [Qt.Key_Enter]: "Return", [Qt.Key_Space]: "Space", [Qt.Key_Tab]: "Tab",
            [Qt.Key_Backtab]: "Tab", [Qt.Key_Backspace]: "BackSpace", [Qt.Key_Delete]: "Delete", [Qt.Key_Insert]: "Insert",
            [Qt.Key_Home]: "Home", [Qt.Key_End]: "End", [Qt.Key_PageUp]: "Page_Up", [Qt.Key_PageDown]: "Page_Down",
            [Qt.Key_Left]: "Left", [Qt.Key_Right]: "Right", [Qt.Key_Up]: "Up", [Qt.Key_Down]: "Down",
            [Qt.Key_Slash]: "Slash", [Qt.Key_Question]: "Slash", [Qt.Key_Period]: "Period", [Qt.Key_Greater]: "Period",
            [Qt.Key_Comma]: "Comma", [Qt.Key_Less]: "Comma", [Qt.Key_Minus]: "Minus", [Qt.Key_Underscore]: "Minus",
            [Qt.Key_Equal]: "Equal", [Qt.Key_Plus]: "Equal", [Qt.Key_Semicolon]: "Semicolon", [Qt.Key_Colon]: "Semicolon",
            [Qt.Key_Apostrophe]: "Apostrophe", [Qt.Key_QuoteDbl]: "Apostrophe", [Qt.Key_BracketLeft]: "bracketleft",
            [Qt.Key_BraceLeft]: "bracketleft", [Qt.Key_BracketRight]: "bracketright", [Qt.Key_BraceRight]: "bracketright",
            [Qt.Key_Backslash]: "backslash", [Qt.Key_Bar]: "backslash", [Qt.Key_QuoteLeft]: "grave", [Qt.Key_AsciiTilde]: "grave",
            [Qt.Key_Print]: "Print", [Qt.Key_Pause]: "Pause"
        };
        return m[k] ?? "";
    }
    function modNames(mods) {
        const l = [];
        if (mods & Qt.MetaModifier) l.push("SUPER");
        if (mods & Qt.ControlModifier) l.push("CTRL");
        if (mods & Qt.AltModifier) l.push("ALT");
        if (mods & Qt.ShiftModifier) l.push("SHIFT");
        return l;
    }

    WSection {
        WCard {
            icon: "keyboard_command_key"
            title: `${page.rows.filter(r => !r.off).length} shortcuts`
            description: page.status !== "" ? page.status : "Change one by pressing new keys. Your changes stay when Phoenix updates"
            Rectangle {
                implicitWidth: 260; implicitHeight: 36
                radius: 12
                color: Appearance.colors.colLayer4
                border.width: search.activeFocus ? 2 : 0
                border.color: Appearance.colors.colPrimary
                TextField {
                    id: search
                    anchors.fill: parent
                    leftPadding: 10
                    background: null
                    placeholderText: "Search shortcuts"
                    placeholderTextColor: Appearance.colors.colSubtext
                    color: Appearance.colors.colOnLayer3
                    font.family: Appearance.font.family.main
                    font.pixelSize: Appearance.font.pixelSize.small
                    onTextChanged: page.query = text
                }
            }
            WButton { accent: true; buttonText: "Add a shortcut"; onClicked: capture.openAdd() }
        }
    }

    Repeater {
        model: page.groups
        WSection {
            id: grp
            required property var modelData
            title: grp.modelData.name === "Yours" ? "Your own shortcuts" : grp.modelData.name
            Repeater {
                model: grp.modelData.rows
                WCard {
                    id: row
                    required property var modelData
                    minHeight: 54
                    title: row.modelData.what
                    description: row.modelData.off ? "Switched off"
                        : row.modelData.added ? row.modelData.command
                        : row.modelData.changed ? `Changed (default: ${row.modelData.original})` : ""
                    opacity: row.modelData.off ? 0.6 : 1
                    Rectangle {
                        visible: !row.modelData.off
                        implicitWidth: keyText.implicitWidth + 20
                        implicitHeight: 30
                        radius: 8
                        color: Appearance.colors.colLayer4
                        StyledText {
                            id: keyText
                            anchors.centerIn: parent
                            text: row.modelData.keys
                            font.family: Appearance.font.family.monospace
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer3
                        }
                    }
                    WButton {
                        visible: !row.modelData.off
                        buttonText: "Change"
                        onClicked: capture.openChange(row.modelData)
                    }
                    WButton {
                        visible: row.modelData.changed && !row.modelData.added
                        buttonText: row.modelData.off ? "Switch on" : "Reset"
                        onClicked: page.run(["reset", row.modelData.original])
                    }
                    WButton {
                        visible: !row.modelData.off && !row.modelData.changed && !row.modelData.added
                        buttonText: "Off"
                        onClicked: page.run(["off", row.modelData.keys, `${row.modelData.category}: ${row.modelData.what}`])
                    }
                    WButton {
                        visible: row.modelData.added
                        buttonText: "Remove"
                        onClicked: page.run(["remove", row.modelData.keys])
                    }
                }
            }
        }
    }

    // ── press-the-new-keys dialog ──
    // While it's open Hyprland is in the empty shortcut mode "phoenix-boot" (custom/execs.lua), so the keys reach this window instead of
    // running their shortcut (Super+Q would close it). Back to normal on save, cancel, Esc, after 20 s, or if it closes.
    Item {
        id: capture
        parent: page.parent ? page.parent : page
        anchors.fill: parent
        visible: false
        z: 50
        property var target: null            // the shortcut being changed, null = adding one
        property var mods: []
        property string key: ""
        property string conflict: ""
        readonly property string combo: [...capture.mods, ...(capture.key ? [capture.key] : [])].join(" + ")
        readonly property bool complete: capture.key !== "" && (capture.mods.length > 0 || /^F\d+$|^Print$|^Pause$/.test(capture.key))
        function begin() {
            capture.mods = []; capture.key = ""; capture.conflict = "";
            capture.visible = true;
            Hyprland.dispatch(`hl.dsp.submap("phoenix-boot")`);
            safety.restart();
            catcher.forceActiveFocus();
        }
        function openChange(r) { capture.target = r; addName.text = ""; addCmd.text = ""; begin(); }
        function openAdd() { capture.target = null; addName.text = ""; addCmd.text = ""; begin(); }
        function close() {
            if (!capture.visible) return;
            capture.visible = false;
            safety.stop();
            Hyprland.dispatch(`hl.dsp.submap("reset")`);
        }
        function save(force) {
            const extra = force ? ["--force"] : [];
            if (capture.target) page.run(["set", capture.target.original, capture.combo].concat(extra));
            else page.run(["add", capture.combo, addCmd.text.trim(), addName.text.trim() || addCmd.text.trim()].concat(extra));
        }
        Timer { id: safety; interval: 20000; onTriggered: capture.close() }
        Component.onDestruction: if (capture.visible) Hyprland.dispatch(`hl.dsp.submap("reset")`)
        Connections { target: GlobalStates; function onSettingsOpenChanged() { if (!GlobalStates.settingsOpen) capture.close() } }

        Rectangle { anchors.fill: parent; color: Appearance.colors.colScrim; opacity: 0.6 }
        MouseArea { anchors.fill: parent; onClicked: capture.close() }
        Rectangle {
            anchors.centerIn: parent
            width: 520
            height: dlg.implicitHeight + 48
            radius: Appearance.rounding.large
            color: Appearance.m3colors.m3surfaceContainerHigh
            MouseArea { anchors.fill: parent }   // clicks inside don't close it
            ColumnLayout {
                id: dlg
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 24 }
                spacing: 14
                StyledText {
                    text: capture.target ? `Change “${capture.target.what}”` : "Add a shortcut"
                    font.pixelSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnLayer2
                }
                ColumnLayout {
                    visible: !capture.target
                    spacing: 8
                    Layout.fillWidth: true
                    TextField {
                        id: addName
                        Layout.fillWidth: true
                        placeholderText: "Name"
                        color: Appearance.colors.colOnLayer2
                        font.family: Appearance.font.family.main
                        background: Rectangle { radius: 10; color: Appearance.colors.colLayer4 }
                        onActiveFocusChanged: if (!activeFocus) catcher.forceActiveFocus()
                    }
                    TextField {
                        id: addCmd
                        Layout.fillWidth: true
                        placeholderText: "Command"
                        color: Appearance.colors.colOnLayer2
                        font.family: Appearance.font.family.monospace
                        background: Rectangle { radius: 10; color: Appearance.colors.colLayer4 }
                    }
                }
                StyledText {
                    text: "Press the new keys (Esc cancels)"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
                Rectangle {
                    id: catcher
                    Layout.fillWidth: true
                    implicitHeight: 72
                    radius: 16
                    color: "transparent"
                    border.width: 2
                    border.color: catcher.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                    focus: true
                    StyledText {
                        anchors.centerIn: parent
                        text: capture.combo || "…"
                        font.family: Appearance.font.family.monospace
                        font.pixelSize: Appearance.font.pixelSize.huge
                        color: Appearance.colors.colOnLayer2
                    }
                    MouseArea { anchors.fill: parent; onClicked: catcher.forceActiveFocus() }
                    Keys.onPressed: e => {
                        e.accepted = true;
                        safety.restart();
                        if (e.key === Qt.Key_Escape && e.modifiers === Qt.NoModifier) { capture.close(); return; }
                        capture.conflict = "";
                        capture.mods = page.modNames(e.modifiers);
                        const n = page.keyName(e);
                        if (n) capture.key = n;
                    }
                }
                Rectangle {
                    visible: capture.conflict !== ""
                    Layout.fillWidth: true
                    implicitHeight: warn.implicitHeight + 24
                    radius: 14
                    color: Appearance.colors.colErrorContainer
                    StyledText {
                        id: warn
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 14 }
                        wrapMode: Text.Wrap
                        text: `${capture.combo} is used by “${capture.conflict}”. Use anyway turns that one off`
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnErrorContainer
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Item { Layout.fillWidth: true }
                    WButton { buttonText: "Cancel"; onClicked: capture.close() }
                    WButton {
                        accent: true
                        enabled: capture.complete && !writeProc.running && (capture.target !== null || addCmd.text.trim() !== "")
                        buttonText: capture.conflict !== "" ? "Use anyway" : "Save"
                        onClicked: capture.save(capture.conflict !== "")
                    }
                }
            }
        }
    }
}
