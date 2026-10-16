pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Phone Link (Phoenix P6, 2026-10-15): your phone through KDE Connect, for the sidebar's phone card and
// Settings › Bluetooth & devices › Phone. The data comes from scripts/phonelink/phonelink.py (watch), which talks to
// KDE Connect's daemon; set it up once with `phoenix phone-link setup` (installs it, opens the firewall locally).
Singleton {
    id: root

    property bool installed: false
    property bool running: false
    property var devices: []
    readonly property var paired: devices.filter(d => d.paired)
    // the phone the card shows: a connected paired one first, else any paired one
    readonly property var phone: paired.find(d => d.reachable) ?? paired[0] ?? null
    readonly property var pairRequests: devices.filter(d => d.pairRequested && !d.paired)
    readonly property string helper: Quickshell.shellPath("scripts/phonelink/phonelink.py")

    function run(args) { Quickshell.execDetached(["python3", root.helper].concat(args)) }
    function ring(id) { run(["ring", id]) }
    function sendClipboard(id) { run(["clipboard", id]) }
    function browse(id) { run(["browse", id]) }
    function messages(id) { run(["messages", id]) }
    function media(id, action) { run(["media", id, action]) }
    function reply(id, replyId, text) { run(["reply", id, replyId, text]) }
    function dismiss(id, notificationId) { run(["dismiss", id, notificationId]) }
    function pair(id) { run(["pair", id]) }
    function unpair(id) { run(["unpair", id]) }
    function accept(id) { run(["accept", id]) }
    function reject(id) { run(["reject", id]) }
    function refresh() { run(["refresh"]) }
    function setPlugin(id, plugin, on) { run(["plugin", id, plugin, on ? "on" : "off"]) }
    // pick files, then send them (the same file picker the rest of Phoenix uses)
    function sendFiles(id) {
        Quickshell.execDetached(["bash", "-c", `f=$(phoenix-file-picker open "$HOME" "All files" "*" 2>/dev/null); `
            + `[ -n "$f" ] && python3 '${root.helper}' share '${id}' "$f"`])
    }
    function setup() {
        Quickshell.execDetached(["kitty", "--class", "phoenix-setup", "--title", "Set up Phone Link", "--hold",
            "bash", "-c", "phoenix phone-link setup; echo; echo 'You can close this window.'"])
    }

    // newest photos (asks the phone for its storage the first time): photosFor(id) fills root.photos
    property var photos: []
    property string photosFor: ""
    property bool photosLoading: false
    function loadPhotos(id) {
        if (!id || photoProc.running) return
        root.photosFor = id
        root.photosLoading = true
        photoProc.command = ["python3", root.helper, "photos", id]
        photoProc.running = true
    }
    Process {
        id: photoProc
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.photos = JSON.parse(text).photos ?? [] } catch (e) { root.photos = [] }
                root.photosLoading = false
            }
        }
    }

    Process {
        id: watcher
        running: true
        command: ["python3", root.helper, "watch", "2"]
        stdout: SplitParser {
            onRead: line => {
                let d
                try { d = JSON.parse(line) } catch (e) { return }
                root.installed = d.installed ?? false
                root.running = d.running ?? false
                root.devices = d.devices ?? []
            }
        }
        // restarts if the helper stops (KDE Connect restarted, python error)
        onRunningChanged: if (!running) restart.start()
    }
    Timer { id: restart; interval: 5000; onTriggered: watcher.running = true }
}
