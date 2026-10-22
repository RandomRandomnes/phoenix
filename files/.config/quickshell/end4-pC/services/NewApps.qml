pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

// New apps in the Super menu (Phoenix, 2026-10-16, ours; not upstream). Remembers every app it has seen
// (~/.local/state/phoenix/new-apps.json). An app that turns up later (a package, Flatpak, Steam or Ascendara game) is
// added to the app grid when it shows only chosen apps (Config overview.appGridApps) and gets a "new" dot until you
// open it. Settings › Personalization › Super menu apps › "Add new apps automatically" (overview.appGridAddNew).
// The first run only remembers what's installed: nothing already there counts as new.
Singleton {
    id: root

    property bool loaded: false
    readonly property var fresh: adapter.fresh
    function isNew(id) { return root.fresh.indexOf(id) !== -1 }
    function opened(id) {
        if (root.isNew(id)) adapter.fresh = adapter.fresh.filter(x => x !== id)
    }

    readonly property var appIds: AppSearch.list.filter(e => !e.noDisplay).map(e => e.id)
    onAppIdsChanged: settle.restart()
    // the app list fills in over the first moments after a start and changes in bursts during installs: wait for it
    Timer {
        id: settle
        interval: 5000
        onTriggered: root.check()
    }

    function check() {
        if (!root.loaded || !Config.ready || root.appIds.length === 0) return
        const seen = adapter.seen
        if (seen.length === 0) {           // first run: remember what's installed, nothing is new
            adapter.seen = root.appIds.slice()
            return
        }
        // once (2026-10-22): Phoenix's own Settings and Task Manager into a hand-picked grid; they existed before the
        // first run, so they never counted as new. Removed by hand afterwards = stays removed.
        if (!adapter.phoenixAppsAdded) {
            adapter.phoenixAppsAdded = true
            const o0 = Config.options.overview
            if (!o0.appGridShowAll) {
                const have0 = o0.appGridApps.map(x => x.toLowerCase())
                const ours = ["phoenix-settings", "phoenix-task-manager"].filter(id => root.appIds.indexOf(id) !== -1 && have0.indexOf(id) === -1)
                if (ours.length > 0) o0.appGridApps = o0.appGridApps.concat(ours)
            }
        }
        const added = root.appIds.filter(id => seen.indexOf(id) === -1)
        if (added.length === 0) return
        adapter.seen = seen.concat(added)
        if (Config.options.overview.appGridAddNew === false) return
        adapter.fresh = adapter.fresh.concat(added.filter(id => adapter.fresh.indexOf(id) === -1))
        const o = Config.options.overview
        if (!o.appGridShowAll) {
            const have = o.appGridApps.map(x => x.toLowerCase())
            const more = added.filter(id => have.indexOf(id.toLowerCase()) === -1 && !(o.appGridHideSystem && AppSearch.isSystemApp(id)))
            if (more.length > 0) o.appGridApps = o.appGridApps.concat(more)
        }
    }

    FileView {
        id: file
        path: `${Quickshell.env("HOME")}/.local/state/phoenix/new-apps.json`
        watchChanges: false
        onAdapterUpdated: writeAdapter()
        onLoaded: { root.loaded = true; settle.restart() }
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) { root.loaded = true; writeAdapter(); settle.restart() }
        }
        JsonAdapter {
            id: adapter
            property list<string> seen: []
            property list<string> fresh: []
            property bool phoenixAppsAdded: false
        }
    }
}
