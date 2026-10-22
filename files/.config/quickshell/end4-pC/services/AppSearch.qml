pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import Quickshell
import Quickshell.Io
import QtQuick

/**
 * - Eases fuzzy searching for applications by name
 * - Guesses icon name for window class name
 */
Singleton {
    id: root

    // Uninstall an app (Settings › Apps › Installed apps and the Super menu's right-click menu; moved here 2026-10-16)
    function uninstall(entry) {
        // pacman package (or flatpak) that owns the .desktop file; pacman/flatpak ask to confirm
        const script = `id='${entry.id}'
f=$(find ~/.local/share/applications /usr/share/applications /usr/local/share/applications /var/lib/flatpak/exports/share/applications ~/.local/share/flatpak/exports/share/applications -name "$id.desktop" 2>/dev/null | head -1)
echo "Uninstalling: ${entry.name.replace(/'/g, "")}"; echo "Desktop file: $f"; echo
if [ -z "$f" ]; then echo "Couldn't find its desktop file."; exit 1; fi
gid=$(grep -oP 'steam://rungameid/\\K[0-9]+' "$f" | head -1)
if [ -n "$gid" ]; then echo "A Steam game: Steam asks to confirm."; steam "steam://uninstall/$gid" >/dev/null 2>&1 & disown; exit 0; fi
case "$f" in
  *flatpak*) flatpak uninstall -y --noninteractive "$id" ;;
  "$HOME"/*) echo "@@msg This is a user app (not from a package): delete $f to remove it from menus."; exit 1 ;;
  *) pkg=$(pacman -Qqo "$f") && sudo pacman -Rns --noconfirm "$pkg" ;;
esac`;
        // a background job (2026-10-16; was a terminal window): the caller asks to confirm first; the password in the
        // shell's own dialog; a notification when it's done
        Tasks.run("uninstall", ["bash", "-c", script], { title: `Uninstalling ${entry.name}`,
            doneText: `${entry.name} was uninstalled.`, askpassMessage: `Enter your password to uninstall ${entry.name}` });
    }
    // ── One app/icon lookup for all of Phoenix (2026-10-16) ──
    // The desktop entry for an id: exact desktop id, then window class (StartupWMClass), then a reverse-domain id
    // ending in it (org.kde.dolphin for "dolphin"), then Quickshell's heuristic. Used by the app grid, Settings, the
    // Task Manager, window rules and startup apps (they each had their own matcher).
    function entryFor(id) {
        if (!id) return null;
        const l = id.toLowerCase();
        const apps = root.list;
        return apps.find(e => e.id.toLowerCase() === l)
            ?? apps.find(e => (e.startupClass ?? "").toLowerCase() === l)
            ?? apps.find(e => e.id.toLowerCase().endsWith("." + l))
            ?? DesktopEntries.heuristicLookup(id)
            ?? null;
    }
    // Icon name for an app id or window class (its desktop entry's icon, else a guess)
    function iconFor(id) {
        return root.entryFor(id)?.icon || root.guessIcon(id ?? "");
    }
    // Icon file for an icon name, following the icon theme chosen in Settings (SystemAppearance), like the dock and
    // taskbar do: Quickshell.iconPath alone kept showing the old theme's icons after a theme change.
    function iconPath(name, fallback) {
        if (!name) return SystemAppearance.iconPath(fallback ?? "application-x-executable", "image-missing");
        if (name.startsWith("/")) return "file://" + name;
        if (name.startsWith("file:") || name.startsWith("image:")) return name;
        return SystemAppearance.iconPath(name, fallback ?? "application-x-executable");
    }

    property bool sloppySearch: Config.options?.search.sloppy ?? false
    property real scoreThreshold: 0.2
    property var substitutions: ({
        "code-url-handler": "visual-studio-code",
        "Code": "visual-studio-code",
        "gnome-tweaks": "org.gnome.tweaks",
        "pavucontrol-qt": "pavucontrol",
        "wps": "wps-office2019-kprometheus",
        "wpsoffice": "wps-office2019-kprometheus",
        "footclient": "foot",
    })
    property var regexSubstitutions: [
        {
            "regex": /^steam_app_(\d+)$/,
            "replace": "steam_icon_$1"
        },
        {
            "regex": /Minecraft.*/,
            "replace": "minecraft"
        },
        {
            "regex": /.*polkit.*/,
            "replace": "system-lock-screen"
        },
        {
            "regex": /gcr.prompter/,
            "replace": "system-lock-screen"
        }
    ]

    // Phoenix (2026-10-15): entries marked OnlyShowIn/NotShowIn for other desktops (e.g. KDE's "System Settings",
    // OnlyShowIn=KDE) are left out, as the desktop-entry spec says; Quickshell's list doesn't do that by itself, so the
    // menu showed KDE's settings next to Phoenix's. The files are read here (user entries override system ones).
    property var hiddenHere: []
    Process {
        id: showInScan
        running: true
        command: ["python3", "-c", `
import os, json
desk = set(d for d in os.environ.get("XDG_CURRENT_DESKTOP", "Hyprland").split(":") if d) or {"Hyprland"}
home = os.environ.get("XDG_DATA_HOME") or os.path.expanduser("~/.local/share")
dirs = [home] + (os.environ.get("XDG_DATA_DIRS") or "/usr/local/share:/usr/share").split(":")
seen, hidden = set(), []
for d in dirs:
    base = os.path.join(d, "applications")
    for root, _, files in os.walk(base):
        for f in files:
            if not f.endswith(".desktop"): continue
            did = os.path.relpath(os.path.join(root, f), base)[:-8].replace("/", "-")
            if did in seen: continue
            seen.add(did)
            only = no = None; sect = None
            try:
                for line in open(os.path.join(root, f), errors="ignore"):
                    line = line.strip()
                    if line.startswith("["): sect = line
                    elif sect == "[Desktop Entry]" and line.startswith("OnlyShowIn="): only = set(x for x in line[11:].split(";") if x)
                    elif sect == "[Desktop Entry]" and line.startswith("NotShowIn="): no = set(x for x in line[10:].split(";") if x)
            except OSError: continue
            if (only is not None and not (only & desk)) or (no is not None and (no & desk)): hidden.append(did)
print(json.dumps(hidden))`]
        stdout: StdioCollector { onStreamFinished: { try { root.hiddenHere = JSON.parse(text) } catch (e) {} } }
    }
    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { showInScan.running = true }
    }

    // Deduped list to fix double icons
    // Phoenix (2026-10-22): apps that aren't opened by hand on Phoenix, kept out of the Super menu grid (search still
    // finds them; Settings › Personalization › Super menu apps › "Hide system apps", overview.appGridHideSystem):
    // developer and helper tools that packages bring along, and KDE / GTK apps whose job Phoenix does itself.
    readonly property var systemApps: [
        // developer and helper tools
        "assistant", "designer", "linguist", "qdbusviewer", "qv4l2", "qvidcap", "lstopo", "uuctl", "cmake-gui",
        "avahi-discover", "bssh", "bvnc", "org.kde.drkonqi.coredump.gui", "org.kde.heaptrack", "org.gnome.Sysprof",
        // replaced by Phoenix: Task Manager, Phone Link, Settings › Network / Bluetooth / Sound, kitty, screenshots
        "org.kde.plasma-systemmonitor", "org.kde.kdeconnect.app", "org.kde.kdeconnect.nonplasma", "org.kde.kdeconnect.sms",
        "nm-connection-editor", "blueman-manager", "blueman-adapters", "pavucontrol-qt", "pavucontrol",
        "org.kde.konsole", "org.kde.spectacle"
    ]
    function isSystemApp(id) { return root.systemApps.indexOf(id) !== -1 }

    readonly property list<DesktopEntry> list: Array.from(DesktopEntries.applications.values)
        .filter((app, index, self) => 
            index === self.findIndex((t) => (
                t.id === app.id
            ))
        && !root.hiddenHere.includes(app.id)
    )
    
    readonly property var preppedNames: list.map(a => ({
        name: Fuzzy.prepare(`${a.name} `),
        entry: a
    }))

    readonly property var preppedIcons: list.map(a => ({
        name: Fuzzy.prepare(`${a.icon} `),
        entry: a
    }))

    function fuzzyQuery(search: string): var { // Idk why list<DesktopEntry> doesn't work
        if (root.sloppySearch) {
            const results = list.map(obj => ({
                entry: obj,
                score: Levendist.computeScore(obj.name.toLowerCase(), search.toLowerCase())
            })).filter(item => item.score > root.scoreThreshold)
                .sort((a, b) => b.score - a.score)
            return results
                .map(item => item.entry)
        }

        return Fuzzy.go(search, preppedNames, {
            all: true,
            key: "name"
        }).map(r => {
            return r.obj.entry
        });
    }

    function iconExists(iconName) {
        if (!iconName || iconName.length == 0) return false;
        return (SystemAppearance.iconPath(iconName, true).length > 0) 
            && !iconName.includes("image-missing");
    }

    function getReverseDomainNameAppName(str) {
        return str.split('.').slice(-1)[0]
    }

    function getKebabNormalizedAppName(str) {
        return str.toLowerCase().replace(/\s+/g, "-");
    }

    function getUndescoreToKebabAppName(str) {
        return str.toLowerCase().replace(/_/g, "-");
    }

    function guessIcon(str) {
        if (!str || str.length == 0) return "image-missing";

        // Quickshell's desktop entry lookup
        const entry = DesktopEntries.byId(str);
        if (entry) return entry.icon;

        // Normal substitutions
        if (substitutions[str]) return substitutions[str];
        if (substitutions[str.toLowerCase()]) return substitutions[str.toLowerCase()];

        // Regex substitutions
        for (let i = 0; i < regexSubstitutions.length; i++) {
            const substitution = regexSubstitutions[i];
            const replacedName = str.replace(
                substitution.regex,
                substitution.replace,
            );
            if (replacedName != str) return replacedName;
        }

        // Icon exists -> return as is
        if (iconExists(str)) return str;


        // Simple guesses
        const lowercased = str.toLowerCase();
        if (iconExists(lowercased)) return lowercased;

        const reverseDomainNameAppName = getReverseDomainNameAppName(str);
        if (iconExists(reverseDomainNameAppName)) return reverseDomainNameAppName;

        const lowercasedDomainNameAppName = reverseDomainNameAppName.toLowerCase();
        if (iconExists(lowercasedDomainNameAppName)) return lowercasedDomainNameAppName;

        const kebabNormalizedGuess = getKebabNormalizedAppName(str);
        if (iconExists(kebabNormalizedGuess)) return kebabNormalizedGuess;

        const undescoreToKebabGuess = getUndescoreToKebabAppName(str);
        if (iconExists(undescoreToKebabGuess)) return undescoreToKebabGuess;

        // Search in desktop entries
        const iconSearchResults = Fuzzy.go(str, preppedIcons, {
            all: true,
            key: "name"
        }).map(r => {
            return r.obj.entry
        });
        if (iconSearchResults.length > 0) {
            const guess = iconSearchResults[0].icon
            if (iconExists(guess)) return guess;
        }

        const nameSearchResults = root.fuzzyQuery(str);
        if (nameSearchResults.length > 0) {
            const guess = nameSearchResults[0].icon
            if (iconExists(guess)) return guess;
        }

        // Quickshell's desktop entry lookup
        const heuristicEntry = DesktopEntries.heuristicLookup(str);
        if (heuristicEntry) return heuristicEntry.icon;

        // Give up
        return "application-x-executable";
    }
}
