import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root
    signal requestBluetoothDialog()
    property bool barOpen: true
    property bool barStyleEditorOpen: false
    property bool crosshairOpen: false
    property bool equalizerOpen: false
    property bool sidebarLeftOpen: false
    property bool sidebarRightOpen: false
    property bool mediaControlsOpen: false
    property bool osdBrightnessOpen: false
    property bool settingsOpen: false
    property bool taskManagerOpen: false     // the Task Manager window (modules/ii/taskManager, Phoenix 2026-10-16)
    property string taskManagerPage: ""
    property bool osdVolumeOpen: false
    property bool oskOpen: false
    property bool overlayOpen: false
    property bool overviewOpen: false
    property bool regionSelectorOpen: false
    property bool searchOpen: false
    property bool screenLocked: false
    property bool screenLockContainsCharacters: false
    property bool screenUnlockFailed: false
    property bool screenTranslatorOpen: false
    property bool sessionOpen: false
    property bool superDown: false
    property bool superReleaseMightTrigger: true
    property bool wallpaperSelectorOpen: false
    property bool workspaceShowNumbers: false
    property Item currentPageInstance: null
    property list<real> visualizerPoints: []
    property bool desktopWidgetKeyboardFocus: false
    property bool desktopMenuOpen: false
    property var desktopMenuScreen: null
    property real desktopMenuX: 0
    property real desktopMenuY: 0
    property string wallpaperSelectorTarget: "wallpaper"
    property bool dropShelfOpen: false
    property real dropShelfX: 0
    property real dropShelfY: 0
    property string osdIndicatorType: "volume"
    property bool barCenterOnly: false
    property int dashboardPage: 0
    property string dashboardGroup: ""
    property var frameHover: ({})
    function setFrameHover(screenName, side, hovered) {
        const key = `${screenName}:${side}`;
        if ((root.frameHover[key] ?? false) === hovered) return;
        const next = Object.assign({}, root.frameHover);
        next[key] = hovered;
        root.frameHover = next;
    }
    function isFrameHovered(screenName, side) {
        return root.frameHover[`${screenName}:${side}`] ?? false;
    }
    property bool diSessionOpen: false
    property bool startupLockPending: true
    // Phoenix lock-screen sign-in (2026-10-15): the session was started without a password (greetd autologin, see
    // /usr/local/bin/phoenix-session), so the lock screen comes first and the rest of the desktop is only created once
    // the compositor confirms the lock (LockScreen.qml opens the gate). Normal starts: the gate is open from the start.
    readonly property bool lockFirst: Quickshell.env("PHOENIX_LOCK_FIRST") === "1"
    property bool startupGateOpen: !lockFirst
    property bool backgroundVisible: true
    // Phoenix's background services are started from shell.qml (2026-10-08): GlobalStates is also loaded by the setup
    // assistant and quick-start (separate qs -p processes), which then ran a second copy of each service.

    // Wallpaper Engine check lives here (not in Background.qml) so it survives reloadBackground():
    // a freshly created background surface starts with the known value instead of false, which used to
    // paint the static wallpaper over Wallpaper Engine for up to 500ms after every reload (login, wallpaper switch).
    property bool wallpaperEngineRunning: false
    // Wallpapers the shell draws itself (2026-10-03): screen name -> {dir, volume, silent, fps, scaling, props}, parsed from
    // the arguments of the renderer stand-in (~/.local/lib/wallpaper-engine-shell/linux-wallpaperengine, process name
    // linux-wallpaperengine-inshell). Drawn by background/WallpaperEngineLayer.qml. Web wallpapers run in a separate
    // host (process linux-wallpaperengine-web) and are not listed here. props = the app's per-wallpaper settings
    // (--set-property name=value, values kept as strings; the layer converts them using project.json).
    property var wallpaperEngineInShell: ({})
    // wallpaper sound muted via wallpaper-engine-ctl mute (flag file ~/.local/state/wallpaper-engine-muted)
    property bool wallpaperEngineMuted: false
    property string _wallpaperEngineInShellKey: "{}"
    // Wallpaper Engine's workshop folder (2026-10-08): any Steam library, also Flatpak Steam or another drive, from
    // wallpaper-engine-ctl; bare wallpaper ids from the app are resolved in it (was always ~/.local/share/Steam)
    property string wallpaperEngineWorkshop: `${Quickshell.env("HOME")}/.local/share/Steam/steamapps/workshop/content/431960`
    Process {
        running: true
        command: [`${Quickshell.env("HOME")}/.local/bin/wallpaper-engine-ctl`, "workshop"]
        stdout: StdioCollector {
            onStreamFinished: {
                const dir = text.trim();
                if (dir.startsWith("/") && dir !== root.wallpaperEngineWorkshop) {
                    root.wallpaperEngineWorkshop = dir;
                    root._applyWallpaperEngineProcs(root._wallpaperEngineProcs);   // parse the running wallpapers again with it
                }
            }
        }
    }
    property var _wallpaperEngineProcs: []
    function _applyWallpaperEngineProcs(procs) {
        root._wallpaperEngineProcs = procs;
        root.wallpaperEngineRunning = procs.length > 0;
        const parsed = root._parseWallpaperEngineInShell(procs);
        const key = JSON.stringify(parsed);
        if (key !== root._wallpaperEngineInShellKey) {
            root._wallpaperEngineInShellKey = key;
            root.wallpaperEngineInShell = parsed;
        }
    }
    function _parseWallpaperEngineInShell(procs) {
        const result = {};
        for (const args of procs) {
            if (args[0] !== "linux-wallpaperengine-inshell") continue;
            const opts = { volume: 100, silent: false, fps: 60, scaling: "fill", props: {} };
            const dirs = {};
            let pending = [];
            for (let i = 0; i < args.length; i++) {
                const a = args[i], v = args[i + 1];
                if (a === "--screen-root") { pending.push(v); i++; }
                else if (a === "--bg") {
                    if (!v) break;   // --bg as the last argument (QA 2026-10-08: threw and stopped the whole check)
                    const dir = v.startsWith("/") ? v : `${root.wallpaperEngineWorkshop}/${v}`;
                    for (const s of pending) dirs[s] = dir;
                    pending = []; i++;
                }
                else if (a === "--volume") { opts.volume = Number(v); i++; }
                else if (a === "--fps") { opts.fps = Number(v); i++; }
                else if (a === "--scaling") { opts.scaling = v; i++; }
                else if (a === "--silent") opts.silent = true;
                else if (a === "--set-property" && v && v.includes("=")) {
                    opts.props[v.slice(0, v.indexOf("="))] = v.slice(v.indexOf("=") + 1); i++;
                }
            }
            for (const s in dirs) result[s] = Object.assign({ dir: dirs[s] }, opts);
        }
        return result;
    }
    // Wallpaper Engine state (2026-10-16): one long-lived watcher (scripts/wallpapers/we-watch.py) that reads /proc
    // and prints only when something changes; it replaced an `sh` + `pgrep` started twice a second, forever. Runs only
    // while Wallpaper Engine is switched on (Settings › Extras).
    Process {
        id: wallpaperEngineRunningCheck
        running: Config.ready && Config.options.extras.wallpaperEngine === true
        command: ["python3", Quickshell.shellPath("scripts/wallpapers/we-watch.py"), "0.5"]
        stdout: SplitParser {
            onRead: line => {
                let d;
                try { d = JSON.parse(line); } catch (e) { return; }
                root.wallpaperEngineMuted = d.muted === true;
                root._applyWallpaperEngineProcs(d.procs ?? []);
            }
        }
        onRunningChanged: {
            if (running) return;
            if (Config.ready && Config.options.extras.wallpaperEngine === true) { weRestart.restart(); return; }   // it stopped by itself
            root.wallpaperEngineRunning = false;   // switched off: nothing is running any more
            root.wallpaperEngineInShell = ({});
            root._wallpaperEngineInShellKey = "{}";
        }
    }
    Timer { id: weRestart; interval: 2000; onTriggered: wallpaperEngineRunningCheck.running = Qt.binding(() => Config.ready && Config.options.extras.wallpaperEngine === true) }

    Timer {
        interval: 3000
        running: true
        onTriggered: root.startupLockPending = false
    }

    readonly property bool dynamicIslandEnabled: Config.options.bar.layouts.leftLayout.includes("dynamicIsland")
        || Config.options.bar.layouts.middleLayout.includes("dynamicIsland")
        || Config.options.bar.layouts.rightLayout.includes("dynamicIsland")

    signal centeredWallpaperThumpRequested()

    // Shared by desktop (Background) and lock screen (LockSurface) scroll-to-cycle
    readonly property var centeredShapeOptions: [
        "Circle", "Square", "Slanted", "Arch", "Arrow", "SemiCircle", "Oval", "Pill",
        "Triangle", "Diamond", "ClamShell", "Pentagon", "Gem", "Sunny", "VerySunny",
        "Cookie4Sided", "Cookie6Sided", "Cookie7Sided", "Cookie9Sided", "Cookie12Sided",
        "Ghostish", "Clover4Leaf", "Clover8Leaf", "Burst", "SoftBurst", "Flower",
        "Puffy", "PuffyDiamond", "PixelCircle", "Bun", "Heart"
    ]
    function cycleCenteredWallpaperShape(direction) {
        const opts = root.centeredShapeOptions
        const i = opts.indexOf(Config.options.background.centeredWallpaperShape)
        Config.options.background.centeredWallpaperShape = opts[(i + direction + opts.length) % opts.length]
    }

    readonly property var hotCornerOptions: [
        { displayName: Translation.tr("None"),                  value: "none" },
        { displayName: Translation.tr("Left Sidebar"),           value: "sidebarLeftOpen" },
        { displayName: Translation.tr("Right Sidebar"),          value: "sidebarRightOpen" },
        { displayName: Translation.tr("Overview Launcher"),               value: "overviewOpen" },
        { displayName: Translation.tr("Wallpaper Selector"),     value: "wallpaperSelectorOpen" },
        { displayName: Translation.tr("Media Controls"),         value: "mediaControlsOpen" },
        { displayName: Translation.tr("Overlay"),                value: "overlayOpen" },
        { displayName: Translation.tr("ScreenShot Region"),        value: "regionSelectorOpen" },
        { displayName: Translation.tr("Screen Translator"),      value: "screenTranslatorOpen" },
        { displayName: Translation.tr("On-screen Keyboard"),     value: "oskOpen" },
        { displayName: Translation.tr("Session Menu"),           value: "sessionOpen" },
        { displayName: Translation.tr("Equalizer"),           value: "equalizerOpen" }
    ]

    function toggleState(name) {
        if (!name || name === "none") return;
        root[name] = !root[name];
    }
    
    onSidebarRightOpenChanged: {
        if (GlobalStates.sidebarRightOpen) {
            Notifications.timeoutAll();
            Notifications.markAllRead();
        }
    }

    Timer {
        id: barRefreshTimer
        interval: 200
        repeat: false
        onTriggered: {
            root.barOpen = true
        }
    }

    function refreshBar() {
        if (!root.barOpen) return;
        root.barOpen = false
        barRefreshTimer.restart()
    }

    Timer {
        id: backgroundRefreshTimer
        interval: 100
        repeat: false
        onTriggered: {
            root.backgroundVisible = true
        }
    }

    function refreshBackground() {
        if (!root.backgroundVisible) return;
        root.backgroundVisible = false
        backgroundRefreshTimer.restart()
    }

    CompositorGlobalShortcut {
        name: "workspaceNumber"
        description: "Hold to show workspace numbers, release to show icons"
        onPressed: { root.superDown = true }
        onReleased: { root.superDown = false }
    }

    IpcHandler {
        target: "background"
        function toggleCenteredWallpaper(): void {
            Config.options.background.centeredWallpaper = !Config.options.background.centeredWallpaper
        }
        function reloadBackground(): void {
            root.refreshBackground()
        }
    }

     CompositorGlobalShortcut {
        name: "centeredWallpaperToggle"
        description: "Toggles centered wallpaper"
        onPressed: {
            Config.options.background.centeredWallpaper = !Config.options.background.centeredWallpaper
        }
    }
}