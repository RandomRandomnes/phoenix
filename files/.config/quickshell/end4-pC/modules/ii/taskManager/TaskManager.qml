import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common

// The Task Manager as a window of the shell (Phoenix, 2026-10-16; was a separate `qs -p` program): opens instantly
// with the shell's theme and icons and shares its services (startup list, app lookup). Only exists while open, so its
// process sampler (scripts/taskmanager/procs.py) runs only then. Opened by ~/.local/bin/phoenix-task-manager over IPC
// ("taskManager open <page>"); the title bar's ✕ or Super+Q closes it.
Scope {
    id: root

    IpcHandler {
        target: "taskManager"
        function open(page: string): void {
            GlobalStates.taskManagerPage = page;
            if (GlobalStates.taskManagerOpen) root.raise(); else GlobalStates.taskManagerOpen = true;
        }
        function toggle(): void { GlobalStates.taskManagerOpen = !GlobalStates.taskManagerOpen; }
        function close(): void { GlobalStates.taskManagerOpen = false; }
    }
    // already open: bring it to the front (and to this screen's workspace like any window you focus)
    function raise() {
        Hyprland.dispatch(`hl.dsp.focus({ window = "title:^(Task Manager)$" })`);
    }

    Loader {
        active: GlobalStates.taskManagerOpen
        sourceComponent: FloatingWindow {
            id: win
            title: "Task Manager"
            color: Appearance.m3colors.m3background
            // fits the screen it opens on, like Settings (portrait screens swap width and height)
            readonly property var mon: Hyprland.focusedMonitor
            readonly property real monW: (mon?.width ?? 1920) / (mon?.scale || 1)
            readonly property real monH: (mon?.height ?? 1080) / (mon?.scale || 1)
            implicitWidth: Math.max(860, Math.min(1240, monW - 40))
            implicitHeight: Math.max(560, Math.min(820, monH - 120))
            visible: true
            onVisibleChanged: if (!visible) GlobalStates.taskManagerOpen = false   // closed by the window manager
            TaskManagerContent {
                anchors.fill: parent
                startPage: GlobalStates.taskManagerPage
            }
        }
    }
}
