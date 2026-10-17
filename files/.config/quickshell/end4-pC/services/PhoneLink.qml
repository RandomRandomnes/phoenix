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

    // actions go to the running helper (one D-Bus connection, the card updates right after; 2026-10-16), else a one-off run
    function run(args) {
        if (watcher.running) watcher.write(JSON.stringify(args) + "\n");
        else Quickshell.execDetached(["python3", root.helper].concat(args));
    }
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
    // start KDE Connect's service now (when it's switched off at sign-in in Task Manager › Startup)
    function start() { Quickshell.execDetached(["bash", "-c", "pgrep -x kdeconnectd >/dev/null || exec kdeconnectd"]) }
    function setPlugin(id, plugin, on) { run(["plugin", id, plugin, on ? "on" : "off"]) }
    // pick files, then send them (the same file picker the rest of Phoenix uses)
    function sendFiles(id) {
        Quickshell.execDetached(["bash", "-c", `f=$(phoenix-file-picker open "$HOME" "All files" "*" 2>/dev/null); `
            + `[ -n "$f" ] && python3 '${root.helper}' share '${id}' "$f"`])
    }
    // set up / turn off: background jobs (2026-10-16; were terminal windows), progress on the Phone page
    function setup() {
        Tasks.run("phonelink", [`${Quickshell.env("HOME")}/.local/bin/phoenix`, "phone-link", "setup"],
            { title: "Setting up Phone Link", askpassMessage: "Enter your password to install KDE Connect and open its firewall ports" })
    }
    function remove() {
        Tasks.run("phonelink", [`${Quickshell.env("HOME")}/.local/bin/phoenix`, "phone-link", "remove"],
            { title: "Turning off Phone Link", askpassMessage: "Enter your password to close Phone Link's firewall ports" })
    }

    // newest photos (asks the phone for its storage the first time): photosFor(id) fills root.photos
    property var photos: []
    property string photosFor: ""
    property bool photosLoading: false
    function loadPhotos(id) {
        if (!id || root.photosLoading) return
        root.photosFor = id
        root.photosLoading = true
        photoTimeout.restart()
        root.run(["photos", id])
    }
    Timer { id: photoTimeout; interval: 40000; onTriggered: root.photosLoading = false }   // no answer: stop waiting

    Process {
        id: watcher
        running: true
        // event-driven (KDE Connect's D-Bus signals) since 2026-10-16; was a full check every 2 s
        command: ["python3", root.helper, "serve"]
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => {
                let d
                try { d = JSON.parse(line) } catch (e) { return }
                if (d.reply !== undefined) {   // an answer to a command
                    if (d.reply === "photos") { root.photos = d.photos ?? []; root.photosLoading = false; photoTimeout.stop() }
                    return
                }
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
