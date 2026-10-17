pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray

Singleton {
    id: root

    property bool smartTray: Config.options.tray.filterPassive
    property list<var> itemsInUserList: SystemTray.items.values.filter(i => (Config.options.tray.pinnedItems.includes(i.id) && (!smartTray || i.status !== Status.Passive)))
    property list<var> itemsNotInUserList: SystemTray.items.values.filter(i => (!Config.options.tray.pinnedItems.includes(i.id) && (!smartTray || i.status !== Status.Passive)))

    property bool invertPins: Config.options.tray.invertPinnedItems
    property list<var> pinnedItems: invertPins ? itemsNotInUserList : itemsInUserList
    property list<var> unpinnedItems: invertPins ? itemsInUserList : itemsNotInUserList

    // Icons that came through the X11 tray bridge (Wine/Proton programs such as RSI Launcher) have no title or tooltip,
    // only the number of their X11 window as id: look up the program's name (scripts/tray/xembed-name.py; 2026-10-17)
    // after a shell restart the bridge still holds its icons but doesn't announce them again (scripts/tray/reregister.py)
    Timer {
        running: true
        interval: 3000
        onTriggered: reregisterProc.running = true
    }
    Process {
        id: reregisterProc
        command: ["python3", Quickshell.shellPath("scripts/tray/reregister.py")]
    }
    property var xembedNames: ({})
    property var xembedAsked: ({})
    function resolveXembed(id) {
        // asked again when the last answer is over 10 s old (a program's window may have appeared or closed since)
        if (!/^\d+$/.test(id) || Date.now() - (root.xembedAsked[id] ?? 0) < 10000) return;
        root.xembedAsked[id] = Date.now();
        const p = nameProc.createObject(root, { wid: id });
        p.running = true;
    }
    Component {
        id: nameProc
        Process {
            id: np
            property string wid
            command: ["python3", Quickshell.shellPath("scripts/tray/xembed-name.py"), np.wid]
            stdout: StdioCollector {
                onStreamFinished: {
                    const n = text.trim();
                    if (n) { const m = Object.assign({}, root.xembedNames); m[np.wid] = n; root.xembedNames = m; }
                    else root.xembedAsked[np.wid] = 0;   // try again next time
                }
            }
            onExited: np.destroy()
        }
    }
    function nameOf(item) {
        const named = item.tooltipTitle.length > 0 ? item.tooltipTitle : (item.title.length > 0 ? item.title : "");
        if (named) return named;
        root.resolveXembed(item.id);
        return root.xembedNames[item.id] ?? item.id;
    }
    function getTooltipForItem(item) {
        var result = root.nameOf(item);
        if (item.tooltipDescription.length > 0) result += " • " + item.tooltipDescription;
        if (Config.options.tray.showItemId) result += "\n[" + item.id + "]";
        return result;
    }

    // Pinning
    function pin(itemId) {
        var pins = Config.options.tray.pinnedItems;
        if (pins.includes(itemId)) return;
        Config.options.tray.pinnedItems.push(itemId);
    }
    function unpin(itemId) {
        Config.options.tray.pinnedItems = Config.options.tray.pinnedItems.filter(id => id !== itemId);
    }
    function isPinned(itemId) {
        for (var i = 0; i < root.pinnedItems.length; i++) {
            if (root.pinnedItems[i].id === itemId)
                return true;
        }
        return false;
    }

    function togglePin(itemId) {
        var pins = Config.options.tray.pinnedItems;
        if (pins.includes(itemId)) {
            unpin(itemId)
        } else {
            pin(itemId)
        }
    }

}
