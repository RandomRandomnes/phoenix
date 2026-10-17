import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs
import qs.modules.common

// Quick Start as a window of the shell (Phoenix, 2026-10-16; was a separate `qs -p` program): opens instantly in the
// shell's theme. `qs ipc call quickStart open [page]` (phoenix-open quickstart, the app menu, Settings › Extras, the
// setup assistant when it finishes). Exists only while open.
Scope {
    id: root
    property bool open: false
    property string page: ""

    IpcHandler {
        target: "quickStart"
        function open(page: string): void {
            root.page = page;
            if (root.open) Hyprland.dispatch(`hl.dsp.focus({ window = "title:^(Phoenix Quick Start)$" })`);
            else root.open = true;
        }
        function close(): void { root.open = false; }
    }

    Loader {
        active: root.open
        sourceComponent: FloatingWindow {
            title: "Phoenix Quick Start"
            color: Appearance.m3colors.m3background
            implicitWidth: 980
            implicitHeight: 700
            visible: true
            onVisibleChanged: if (!visible) root.open = false   // closed by the window manager
            QuickStartContent {
                anchors.fill: parent
                startPage: root.page
                onDone: root.open = false
            }
        }
    }
}
