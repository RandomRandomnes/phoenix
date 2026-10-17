pragma Singleton
import qs
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/*
 * System updates service. Currently only supports Arch.
 */
Singleton {
    id: root

    property bool available: false
    property alias checking: checkUpdatesProc.running
    property int count: 0
    
    readonly property bool updateAdvised: available && count > Config.options.updates.adviseUpdateThreshold
    readonly property bool updateStronglyAdvised: available && count > Config.options.updates.stronglyAdviseUpdateThreshold

    function load() {}

    // ── Installing (Phoenix, 2026-10-16): one way for every button (taskbar, Settings › Update) ──
    // Automatically: a background job (services/Tasks.qml) with its progress in Settings › Update; the password, only
    // when there are package updates, in the shell's own dialog. Ask first: a terminal, where yay shows the list.
    // Not chosen yet: Settings › Update asks (needsMode).
    property bool needsMode: false
    readonly property bool installing: Tasks.isRunning("update")
    readonly property string updateBin: `${Quickshell.env("HOME")}/.local/bin/system-update`
    function install() {
        if (!Config.options.extras.updatesScript) {   // Settings › Extras: stock illogical-impulse update in a terminal
            Quickshell.execDetached(["kitty", "--hold", "fish", "-i", "-l", "-c", "yay -Syu --combinedupgrade=false"]);
            return;
        }
        const mode = Config.options.extras.updateMode;
        if (mode !== "ask" && mode !== "auto") { root.needsMode = true; root.showPage(); return; }
        root.needsMode = false;
        if (mode === "ask") {
            askProc.running = true;
            return;
        }
        Tasks.run("update", [root.updateBin, "--gui"], { title: "Updates", doneText: "Everything is up to date." });
        root.showPage();
    }
    function showPage() {
        Quickshell.execDetached([`${Quickshell.env("HOME")}/.local/bin/phoenix-open`, "settings", "update"]);
    }
    IpcHandler {
        target: "updates"
        function install(): void { root.install() }
        function check(): void { root.refresh() }
    }
    Process {
        id: askProc
        command: ["kitty", "--class", "phoenix-setup", "--title", "Updates", "fish", "-i", "-l", "-c", "~/.local/bin/system-update"]
        onExited: root.refresh()
    }
    Connections {
        target: Tasks
        function onFinished(id, ok) {
            if (id !== "update") return;
            if (Tasks.job("update")?.flags.includes("needmode")) { Tasks.clear("update"); root.needsMode = true; root.showPage(); }
            root.refresh();
        }
    }
    function refresh() {
        if (!available) return;
        print("[Updates] Checking for system updates")
        checkUpdatesProc.running = true;
    }

    Timer {
        interval: Config.options.updates.checkInterval * 60 * 1000
        repeat: true
        running: Config.ready && Config.options.updates.enableCheck
        onTriggered: {
            print("[Updates] Periodic update check due")
            root.refresh();
        }
    }

    Process {
        id: checkAvailabilityProc
        running: Config.ready && Config.options.updates.enableCheck
        command: ["which", "checkupdates"]
        onExited: (exitCode, exitStatus) => {
            root.available = (exitCode === 0);
            firstCheckTimer.start();
        }
    }

    Timer {
        id: firstCheckTimer
        interval: 60 * 1000
        onTriggered: root.refresh()
    }

    Process {
        id: checkUpdatesProc
        // ours also counts a pending Phoenix release (it carries the shell; applied by ~/.local/bin/system-update);
        // stock otherwise. The shell no longer follows upstream end4-pC (2026-10-09), so its commits aren't counted.
        // phoenix-check (2026-10-09) then notifies once about a pending update that can break the desktop (new Qt or
        // Hyprland version, Quickshell, graphics drivers).
        command: Config.options.extras.updatesScript
            // one check (2026-10-16): phoenix-check counts the packages (checkupdates + yay, cached for Settings › Update)
            // and notifies about critical ones in the same run; it used to run them a second time after this count
            ? ["bash", "-c", "fixes=0; $HOME/.local/bin/custom-update check --quiet >/dev/null 2>&1 && fixes=1; if [ -x $HOME/.local/bin/phoenix-check ]; then n=$($HOME/.local/bin/phoenix-check updates --json --fresh --notify 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin).get(\"pending\", 0))' 2>/dev/null); else n=$(( $(checkupdates 2>/dev/null | wc -l) + $(yay -Qua 2>/dev/null | wc -l) )); fi; echo $(( ${n:-0} + fixes ))"]
            : ["bash", "-c", "pacman=$(checkupdates 2>/dev/null | wc -l); aur=$(yay -Qua 2>/dev/null | wc -l || paru -Qua 2>/dev/null | wc -l || echo 0); echo $((pacman + aur))"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.count = parseInt(text.trim())
            }
        }
    }
}
