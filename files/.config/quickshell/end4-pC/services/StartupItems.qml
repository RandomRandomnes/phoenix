pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

// Everything that can start when you sign in, as one list with an on/off switch each, like Windows' Task Manager ›
// Startup (Phoenix, 2026-10-16, ours; not upstream). Used by the Task Manager and Settings › Apps › Startup.
//   your startup apps   Config hyprland.autostartApps.apps; switching one off keeps it in the list ("off": true,
//                       scripts/hyprland/autostart.py skips it)
//   Phoenix's own       Steam (extras.steamTray), Wallpaper Engine (extras.wallpaperEngine), Phone Link
//                       (extras.phoneLinkStart); only listed when installed
//   KDE Plasma entries  ~/.config/autostart, which only KDE runs: switching one on adds it to your startup apps
// Your own startup script (autostart-user.sh) isn't switchable here: scriptPrograms lists what it runs.
Singleton {
    id: root

    property var plasma: []
    property var scriptPrograms: []
    property bool scriptExists: false
    property string scriptPath: ""
    property var installed: ({})
    function refresh() { helper.running = true }
    Component.onCompleted: refresh()

    readonly property var autostart: Config.options.hyprland.autostartApps
    readonly property var userApps: (autostart.apps ?? []).filter(a => a.cmd && a.cmd.trim().length > 0)

    function nameFor(cmd) {
        const m = cmd.match(/^gtk-launch\s+(\S+)/);
        const id = m ? m[1] : cmd.split(/\s+/)[0].split("/").pop();
        const e = AppSearch.entryFor(id);
        return { name: e?.name ?? id, icon: e?.icon ?? AppSearch.guessIcon(id) };
    }

    // switch one of your startup apps on/off; with the old all-apps switch off, the others stay off
    function setUserOn(cmd, on) {
        let apps = root.userApps.map(a => Object.assign({}, a));
        if (!root.autostart.enable) {
            apps = apps.map(a => Object.assign(a, { off: true }));
            root.autostart.enable = true;
        }
        apps = apps.map(a => {
            if (a.cmd !== cmd) return a;
            const c = Object.assign({}, a);
            if (on) delete c.off; else c.off = true;
            return c;
        });
        root.autostart.apps = apps;
    }
    function addUserApp(cmd) {
        let apps = root.userApps.map(a => Object.assign({}, a));
        if (!root.autostart.enable) {
            apps = apps.map(a => Object.assign(a, { off: true }));
            root.autostart.enable = true;
        }
        if (!apps.some(a => a.cmd === cmd)) apps.push({ cmd: cmd, delay: 0, workspace: 1 });
        else apps = apps.map(a => { if (a.cmd === cmd) delete a.off; return a; });
        root.autostart.apps = apps;
    }

    // one row each: { key, name, icon (system icon) or symbol (Material), source, on, set(bool) }
    readonly property var items: {
        const l = [];
        for (const a of root.userApps) {
            const n = root.nameFor(a.cmd);
            const fromPlasma = root.plasma.find(p => p.exec === a.cmd);
            l.push({ key: "user:" + a.cmd, name: fromPlasma?.name ?? n.name, icon: fromPlasma?.icon || n.icon, symbol: "",
                     source: "Your startup apps", on: root.autostart.enable && !a.off,
                     set: v => root.setUserOn(a.cmd, v) });
        }
        const ex = Config.options.extras;
        if (root.installed.steam)
            l.push({ key: "phoenix:steam", name: "Steam", icon: "steam", symbol: "", source: "Phoenix · in the tray, after you unlock",
                     on: ex.steamTray !== false, set: v => ex.steamTray = v });
        if (root.installed.wallpaperEngine)
            l.push({ key: "phoenix:we", name: "Wallpaper Engine", icon: "", symbol: "animated_images",
                     source: "Phoenix · animated wallpapers",
                     on: ex.wallpaperEngine === true, set: v => ex.wallpaperEngine = v });
        if (root.installed.phoneLink)
            l.push({ key: "phoenix:phone", name: "Phone Link", icon: "", symbol: "smartphone", source: "Phoenix · KDE Connect, after you unlock",
                     on: ex.phoneLinkStart !== false, set: v => ex.phoneLinkStart = v });
        for (const p of root.plasma) {
            if (p.covered !== "" || root.userApps.some(a => a.cmd === p.exec)) continue;
            const known = root.nameFor(p.exec);   // the installed app's icon (the entry's own name often isn't a theme icon)
            l.push({ key: "plasma:" + p.id, name: p.name, icon: AppSearch.list.some(e => e.icon === known.icon) ? known.icon : p.icon, symbol: "",
                     source: "From KDE Plasma's startup list", on: false,
                     set: v => { if (v) root.addUserApp(p.exec); } });
        }
        return l.sort((a, b) => a.name.localeCompare(b.name));
    }

    Process {
        id: helper
        command: ["python3", Quickshell.shellPath("scripts/startup/startup-items.py")]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    root.plasma = d.plasma ?? [];
                    root.scriptPrograms = d.script?.programs ?? [];
                    root.scriptExists = d.script?.exists ?? false;
                    root.scriptPath = d.script?.path ?? "";
                    root.installed = d.installed ?? {};
                } catch (e) {}
            }
        }
    }
}
