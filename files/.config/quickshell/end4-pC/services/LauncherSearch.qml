pragma Singleton

import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.functions
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.modules.ii.settingsW11
import ".."

Singleton {
    id: root

    property string query: ""

    // ── Search modes (Phoenix P13, 2026-10-16): chips under the search bar, Tab / Shift+Tab cycle them ──
    // all = the best few of each kind; the others show one kind only. Symbol prefixes ($ ? = ; : < .) still work.
    readonly property var modes: [
        { id: "all", name: Translation.tr("All"), icon: "apps" },
        { id: "apps", name: Translation.tr("Apps"), icon: "grid_view" },
        { id: "files", name: Translation.tr("Files"), icon: "description" },
        { id: "windows", name: Translation.tr("Windows"), icon: "select_window" },
        { id: "settings", name: Translation.tr("Settings"), icon: "settings" },
        { id: "commands", name: Translation.tr("Commands"), icon: "terminal" },
    ]
    property string mode: "all"
    function cycleMode(step) {
        const i = root.modes.findIndex(m => m.id === root.mode);
        root.mode = root.modes[(i + step + root.modes.length) % root.modes.length].id;
    }
    onQueryChanged: {
        if (root.query === "") root.mode = "all";
        fileQueryTimer.restart();
    }
    onModeChanged: fileQueryTimer.restart()
    Connections {
        target: GlobalStates
        function onOverviewOpenChanged() {
            if (!GlobalStates.overviewOpen) root.mode = "all";
            // warm the file index as soon as the menu opens, so the first file search doesn't wait (2026-10-16)
            else if (!fileProc.running) fileProc.running = true;
        }
    }

    // files: scripts/search/files.py keeps an in-memory index of the home folder and answers one JSON line per query
    property var fileResults: []
    property string fileResultsFor: ""
    readonly property bool wantsFiles: (root.mode === "all" || root.mode === "files") && root.plainQuery.trim().length >= 2
    readonly property string plainQuery: StringUtils.cleanPrefix(root.query, Config.options.search.prefix.app)
    Timer {
        id: fileQueryTimer
        interval: 120
        onTriggered: {
            if (!root.wantsFiles) { root.fileResults = []; root.fileResultsFor = ""; return; }
            if (!fileProc.running) fileProc.running = true;
            fileProc.write(root.plainQuery.replace(/\n/g, " ") + "\n");
        }
    }
    Process {
        id: fileProc
        command: ["python3", Quickshell.shellPath("scripts/search/files.py"), "serve"]
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => {
                let d;
                try { d = JSON.parse(line); } catch (e) { return; }
                if (d.q !== root.plainQuery) return;    // an older query
                root.fileResultsFor = d.q;
                root.fileResults = d.results ?? [];
            }
        }
    }

    function ensurePrefix(prefix) {
        if ([Config.options.search.prefix.action, Config.options.search.prefix.app, Config.options.search.prefix.clipboard, Config.options.search.prefix.emojis, Config.options.search.prefix.symbols, Config.options.search.prefix.math, Config.options.search.prefix.shellCommand, Config.options.search.prefix.webSearch,].some(i => root.query.startsWith(i))) {
            root.query = prefix + root.query.slice(1);
        } else {
            root.query = prefix + root.query;
        }
    }
    
    // https://specifications.freedesktop.org/menu/latest/category-registry.html
    property list<string> mainRegisteredCategories: ["AudioVideo", "Development", "Education", "Game", "Graphics", "Network", "Office", "Science", "Settings", "System", "Utility"]
    property list<string> appCategories: DesktopEntries.applications.values.reduce((acc, entry) => {
        for (const category of entry.categories) {
            if (!acc.includes(category) && mainRegisteredCategories.includes(category)) {
                acc.push(category);
            }
        }
        return acc;
    }, []).sort()

    // Load user action scripts from ~/.config/illogical-impulse/actions/
    // Uses FolderListModel to auto-reload when scripts are added/removed
    property var userActionScripts: {
        const actions = [];
        for (let i = 0; i < userActionsFolder.count; i++) {
            const fileName = userActionsFolder.get(i, "fileName");
            const filePath = userActionsFolder.get(i, "filePath");
            if (fileName && filePath) {
                const actionName = fileName.replace(/\.[^/.]+$/, ""); // strip extension
                actions.push({
                    action: actionName,
                    execute: ((path) => (args) => {
                        Quickshell.execDetached([path, ...(args ? args.split(" ") : [])]);
                    })(FileUtils.trimFileProtocol(filePath.toString()))
                });
            }
        }
        return actions;
    }

    FolderListModel {
        id: userActionsFolder
        folder: Qt.resolvedUrl(Directories.userActions)
        showDirs: false
        showHidden: false
        sortField: FolderListModel.Name
    }

    property var searchActions: [
        {
            action: "accentcolor",
            execute: args => {
                Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--noswitch", "--color", ...(args != '' ? [`${args}`] : [])]);
            }
        },
        {
            action: "dark",
            execute: () => {
                Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", "dark", "--noswitch"]);
            }
        },
        {
            action: "konachanwallpaper",
            execute: () => {
                Quickshell.execDetached([Quickshell.shellPath("scripts/colors/random/random_konachan_wall.sh")]);
            }
        },
        {
            action: "light",
            execute: () => {
                Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", "light", "--noswitch"]);
            }
        },
        {
            action: "superpaste",
            execute: args => {
                if (!/^(\d+)/.test(args.trim())) {
                    // Invalid if doesn't start with numbers
                    Quickshell.execDetached(["notify-send", Translation.tr("Superpaste"), Translation.tr("Usage: <tt>%1superpaste NUM_OF_ENTRIES[i]</tt>\nSupply <tt>i</tt> when you want images\nExamples:\n<tt>%1superpaste 4i</tt> for the last 4 images\n<tt>%1superpaste 7</tt> for the last 7 entries").arg(Config.options.search.prefix.action), "-a", "Shell"]);
                    return;
                }
                const syntaxMatch = /^(?:(\d+)(i)?)/.exec(args.trim());
                const count = syntaxMatch[1] ? parseInt(syntaxMatch[1]) : 1;
                const isImage = !!syntaxMatch[2];
                Cliphist.superpaste(count, isImage);
            }
        },
        {
            action: "todo",
            execute: args => {
                Todo.addTask(args);
            }
        },
        {
            action: "wallpaper",
            execute: () => {
                Hyprland.dispatch(`hl.dsp.global("quickshell:wallpaperSelectorToggle")`)
            }
        },
        {
            action: "wipeclipboard",
            execute: () => {
                Quickshell.execDetached(["bash", "-c", "rm -f ~/.cache/cliphist/db"]);
            }
        },
        {
            action: "unsplash",
            execute: args => {
                if (!args || args.trim().length === 0) {
                    Quickshell.execDetached(["notify-send", "Unsplash", Translation.tr("Usage: /unsplash YOUR_API_KEY"), "-a", "Shell"]);
                    return;
                }
                KeyringStorage.setNestedField(["apiKeys", "unsplash"], args.trim());
                Quickshell.execDetached(["notify-send", "Unsplash", Translation.tr("API key saved!"), "-a", "Shell"]);
            }
        },
        {
            action: "wallhaven",
            execute: args => {
                if (!args || args.trim().length === 0) {
                    Quickshell.execDetached(["notify-send", "Wallhaven", Translation.tr("Usage: /wallhaven YOUR_API_KEY"), "-a", "Shell"]);
                    return;
                }
                KeyringStorage.setNestedField(["apiKeys", "wallhaven"], args.trim());
                Quickshell.execDetached(["notify-send", "Wallhaven", Translation.tr("API key saved!"), "-a", "Shell"]);
            }
        },
        {
            action: "pexels",
            execute: args => {
                if (!args || args.trim().length === 0) {
                    Quickshell.execDetached(["notify-send", "Pexels", Translation.tr("Usage: /pexels YOUR_API_KEY"), "-a", "Shell"]);
                    return;
                }
                KeyringStorage.setNestedField(["apiKeys", "pexels"], args.trim());
                Quickshell.execDetached(["notify-send", "Pexels", Translation.tr("API key saved!"), "-a", "Shell"]);
            }
        },
        {
            action: "openweather",
            execute: args => {
                if (!args || args.trim().length === 0) {
                    Quickshell.execDetached(["notify-send", "OpenWeather", Translation.tr("Usage: /openweather YOUR_API_KEY"), "-a", "Shell"]);
                    return;
                }
                KeyringStorage.setNestedField(["apiKeys", "openweather"], args.trim());
                Quickshell.execDetached(["notify-send", "OpenWeather", Translation.tr("API key saved!"), "-a", "Shell"]);
                Weather.getData();
            }
        },
    ]

    // Combined built-in and user actions
    property var allActions: searchActions.concat(userActionScripts)

    property string mathResult: ""
    property bool clipboardWorkSafetyActive: {
        const enabled = Config.options.workSafety.enable.clipboard;
        const sensitiveNetwork = (StringUtils.stringListContainsSubstring(Network.networkName.toLowerCase(), Config.options.workSafety.triggerCondition.networkNameKeywords));
        return enabled && sensitiveNetwork;
    }

    function containsUnsafeLink(entry) {
        if (entry == undefined)
            return false;
        const unsafeKeywords = Config.options.workSafety.triggerCondition.linkKeywords;
        return StringUtils.stringListContainsSubstring(entry.toLowerCase(), unsafeKeywords);
    }

    Timer {
        id: nonAppResultsTimer
        interval: Config.options.search.nonAppResultDelay
        onTriggered: {
            let expr = root.query;
            if (expr.startsWith(Config.options.search.prefix.math)) {
                expr = expr.slice(Config.options.search.prefix.math.length);
            }
            mathProc.calculateExpression(expr);
        }
    }

    Process {
        id: mathProc
        property list<string> baseCommand: ["qalc", "-t"]
        function calculateExpression(expression) {
            mathProc.running = false;
            mathProc.command = baseCommand.concat(expression);
            mathProc.running = true;
        }
        stdout: SplitParser {
            onRead: data => {
                root.mathResult = data;
            }
        }
    }

    property list<var> results: {
        // Search results are handled here
        ////////////////// Skip? //////////////////
        if (root.query == "")
            return [];

        ///////////// Special cases ///////////////
        if (root.query.startsWith(Config.options.search.prefix.clipboard)) {
            // Clipboard
            const searchString = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.clipboard);
            const clipboardResults = Cliphist.fuzzyQuery(searchString).map((entry, index, array) => {
                const mightBlurImage = Cliphist.entryIsImage(entry) && root.clipboardWorkSafetyActive;
                let shouldBlurImage = mightBlurImage;
                if (mightBlurImage) {
                    shouldBlurImage = shouldBlurImage && (root.containsUnsafeLink(array[index - 1]) || root.containsUnsafeLink(array[index + 1]));
                }
                const type = `#${entry.match(/^\s*(\S+)/)?.[1] || ""}`;
                const pinned = Cliphist.isPinned(entry);
                return resultComp.createObject(null, {
                    rawValue: entry,
                    name: StringUtils.cleanCliphistEntry(entry),
                    verb: "",
                    type: type,
                    clipboard: true,
                    pinned: pinned,
                    execute: () => {
                        Cliphist.copy(entry);
                    },
                    actions: [resultComp.createObject(null, {
                            name: pinned ? Translation.tr("Unpin") : Translation.tr("Pin"),
                            iconName: pinned ? "keep_off" : "keep",
                            iconType: LauncherSearchResult.IconType.Material,
                            execute: () => {
                                Cliphist.togglePin(entry);
                            }
                        }), resultComp.createObject(null, {
                            name: Translation.tr("Delete"),
                            iconName: "delete",
                            iconType: LauncherSearchResult.IconType.Material,
                            execute: () => {
                                Cliphist.deleteEntry(entry);
                            }
                        })],
                    blurImage: shouldBlurImage
                });
            }).filter(Boolean);
            return [...clipboardResults.filter(result => result.pinned), ...clipboardResults.filter(result => !result.pinned)];
        } else if (root.query.startsWith(Config.options.search.prefix.emojis)) {
            // Emojis
            const searchString = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.emojis);
            return Emojis.fuzzyQuery(searchString).map(entry => {
                const emoji = entry.match(/^\s*(\S+)/)?.[1] || "";
                return resultComp.createObject(null, {
                    rawValue: entry,
                    name: entry.replace(/^\s*\S+\s+/, ""),
                    iconName: emoji,
                    iconType: LauncherSearchResult.IconType.Text,
                    verb: Translation.tr("Copy"),
                    type: Translation.tr("Emoji"),
                    execute: () => {
                        Quickshell.clipboardText = entry.match(/^\s*(\S+)/)?.[1];
                    }
                });
            }).filter(Boolean);
        } else if (root.query.startsWith(Config.options.search.prefix.keybinds ?? "<")) {
            // Keybinds
            const searchString = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.keybinds ?? "<");
            const flatBinds = (function flatten(node) {
                let result = [...(node.keybinds ?? [])];
                for (const child of (node.children ?? [])) {
                    result = result.concat(flatten(child));
                }
                return result;
            })(HyprlandKeybinds.keybinds);

            return flatBinds.filter(bind => {
                if (!bind.comment) return false;
                if (searchString.length === 0) return true;
                return bind.comment.toLowerCase().includes(searchString.toLowerCase())
                    || bind.key.toLowerCase().includes(searchString.toLowerCase());
            }).map(bind => {
                const modsStr = bind.mods.join(" + ");
                const keyStr  = modsStr.length > 0 ? `${modsStr} + ${bind.key}` : bind.key;
                return resultComp.createObject(null, {
                    name: bind.comment,
                    iconName: "keyboard",
                    iconType: LauncherSearchResult.IconType.Material,
                    verb: keyStr,
                    type: Translation.tr("Keybind"),
                    comment: keyStr,
                    execute: () => {
                        Quickshell.clipboardText = keyStr;
                    }
                });
            }).filter(Boolean);
        } else if (root.query.startsWith(Config.options.search.prefix.symbols)) {
            // Material Symbols
            const searchString = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.symbols);
            return MaterialSymbolsSearch.fuzzyQuery(searchString).map(entry => {
                const tabIdx = entry.indexOf("\t");
                const symName = tabIdx >= 0 ? entry.slice(0, tabIdx) : entry;
                const symTags = tabIdx >= 0 ? entry.slice(tabIdx + 1) : "";
                return resultComp.createObject(null, {
                    rawValue: entry,
                    name: symName,
                    iconName: symName,
                    iconType: LauncherSearchResult.IconType.Material,
                    verb: Translation.tr("Copy"),
                    type: Translation.tr("Symbol"),
                    comment: symTags,
                    execute: () => {
                        Quickshell.clipboardText = symName;
                    }
                });
            }).filter(Boolean);
        }

        ////////////////// Init ///////////////////
        nonAppResultsTimer.restart();
        const mathResultObject = resultComp.createObject(null, {
            name: root.mathResult,
            verb: Translation.tr("Copy"),
            type: Translation.tr("Math result"),
            fontType: LauncherSearchResult.FontType.Monospace,
            iconName: 'calculate',
            iconType: LauncherSearchResult.IconType.Material,
            execute: () => {
                Quickshell.clipboardText = root.mathResult;
            }
        });
        const appResultObjects = AppSearch.fuzzyQuery(StringUtils.cleanPrefix(root.query, Config.options.search.prefix.app)).map(entry => {
            return resultComp.createObject(null, {
                type: Translation.tr("App"),
                id: entry.id,
                name: entry.name,
                iconName: entry.icon,
                iconType: LauncherSearchResult.IconType.System,
                verb: Translation.tr("Open"),
                execute: () => {
                    NewApps.opened(entry.id);   // clears the Super menu's "new" dot
                    if (!entry.runInTerminal)
                        entry.execute();
                    else {
                        // Probably needs more proper escaping, but this will do for now
                        Quickshell.execDetached(["bash", '-c', `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(entry.command.join(' '))}'`]);
                    }
                },
                comment: entry.comment,
                runInTerminal: entry.runInTerminal,
                genericName: entry.genericName,
                keywords: entry.keywords,
                actions: entry.actions.map(action => {
                    return resultComp.createObject(null, {
                        name: action.name,
                        iconName: action.icon,
                        iconType: LauncherSearchResult.IconType.System,
                        execute: () => {
                            if (!action.runInTerminal)
                                action.execute();
                            else {
                                Quickshell.execDetached(["bash", '-c', `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(action.command.join(' '))}'`]);
                            }
                        }
                    });
                })
            });
        });
        ////////////////// Settings search //////////////////
        // Phoenix's own Settings pages (settingsW11 WState.index), so a result opens the exact page
        const settingsResults = WState.search(StringUtils.cleanPrefix(root.query, Config.options.search.prefix.app)).map(entry => {
            const where = [WState.categoryName(entry.page), entry.sub ? WState.subTitle(entry.page, entry.sub) : ""].filter(part => part && part !== entry.title).join(" › ");
            return resultComp.createObject(null, {
                name: entry.title,
                comment: where,
                verb: Translation.tr("Go"),
                type: Translation.tr("Settings") + (where ? ` • ${where}` : ""),
                iconName: WState.categories.find(c => c.id === entry.page)?.icon ?? "settings",
                iconType: LauncherSearchResult.IconType.Material,
                execute: () => {
                    root.query = "";
                    GlobalStates.overviewOpen = false;
                    GlobalStates.openSettings();
                    WState.go(entry.page, entry.sub, entry.highlight ?? "");
                }
            });
        });
        ////////////////// Open windows //////////////////
        const winWords = root.plainQuery.toLowerCase().split(/\s+/).filter(w => w);
        const windowResults = (HyprlandData.windowList ?? []).filter(w => {
            const hay = `${w.title ?? ""} ${w.class ?? ""} ${w.initialTitle ?? ""}`.toLowerCase();
            return winWords.length > 0 && winWords.every(word => hay.indexOf(word) !== -1);
        }).map(w => resultComp.createObject(null, {
            name: w.title || w.class,
            comment: Translation.tr("Workspace %1").arg(w.workspace?.name ?? w.workspace?.id ?? "?") + (w.class ? ` · ${w.class}` : ""),
            verb: Translation.tr("Switch to"),
            type: Translation.tr("Open window"),
            iconName: AppSearch.guessIcon(w.class ?? ""),
            iconType: LauncherSearchResult.IconType.System,
            execute: () => {
                GlobalStates.overviewOpen = false;
                Hyprland.dispatch(`hl.dsp.focus({ window = "address:${w.address}" })`);
            }
        }));
        ////////////////// Files //////////////////
        const fileResultObjects = (root.fileResultsFor === root.plainQuery ? root.fileResults : []).map(f => resultComp.createObject(null, {
            name: f.name,
            comment: f.dir + (f.recent ? ` · ${Translation.tr("opened recently")}` : ""),
            verb: f.isDir ? Translation.tr("Open folder") : Translation.tr("Open"),
            type: (f.isDir ? Translation.tr("Folder") : Translation.tr("File")) + ` • ${f.dir}` + (f.recent ? ` • ${Translation.tr("opened recently")}` : ""),
            iconName: f.isDir ? "folder" : "description",
            iconType: LauncherSearchResult.IconType.Material,
            execute: () => {
                GlobalStates.overviewOpen = false;
                if (f.isDir) Quickshell.execDetached([`${Quickshell.env("HOME")}/.local/bin/phoenix-open`, "files", f.path]);
                else Quickshell.execDetached(["xdg-open", f.path]);
            },
            actions: (f.isDir ? [] : [resultComp.createObject(null, {
                name: Translation.tr("Open the folder"),
                iconName: "folder_open",
                iconType: LauncherSearchResult.IconType.Material,
                execute: () => {
                    GlobalStates.overviewOpen = false;
                    Quickshell.execDetached([`${Quickshell.env("HOME")}/.local/bin/phoenix-open`, "files", f.path.substring(0, f.path.lastIndexOf("/"))]);
                }
            })]).concat([resultComp.createObject(null, {
                // the Super menu's Pinned tab (P14, 2026-10-16)
                name: Config.options.overview.pinnedItems.includes(f.path) ? Translation.tr("Unpin from Super menu") : Translation.tr("Pin to Super menu"),
                iconName: Config.options.overview.pinnedItems.includes(f.path) ? "keep_off" : "keep",
                iconType: LauncherSearchResult.IconType.Material,
                execute: () => {
                    const o = Config.options.overview;
                    o.pinnedItems = o.pinnedItems.includes(f.path) ? o.pinnedItems.filter(p => p !== f.path) : o.pinnedItems.concat([f.path]);
                }
            })])
        }));
        const commandResultObject = resultComp.createObject(null, {
            name: StringUtils.cleanPrefix(root.query, Config.options.search.prefix.shellCommand).replace("file://", ""),
            verb: Translation.tr("Run"),
            type: Translation.tr("Command"),
            fontType: LauncherSearchResult.FontType.Monospace,
            iconName: 'terminal',
            iconType: LauncherSearchResult.IconType.Material,
            execute: () => {
                let cleanedCommand = root.query.replace("file://", "");
                cleanedCommand = StringUtils.cleanPrefix(cleanedCommand, Config.options.search.prefix.shellCommand);
                if (cleanedCommand.startsWith(Config.options.search.prefix.shellCommand)) {
                    cleanedCommand = cleanedCommand.slice(Config.options.search.prefix.shellCommand.length);
                }
                Quickshell.execDetached(["bash", "-c", root.query.startsWith('sudo') ? `${Config.options.apps.terminal} fish -C '${cleanedCommand}'` : cleanedCommand]);
            }
        });
        const webSearchResultObject = resultComp.createObject(null, {
            name: StringUtils.cleanPrefix(root.query, Config.options.search.prefix.webSearch),
            verb: Translation.tr("Search"),
            type: Translation.tr("Web search"),
            iconName: 'travel_explore',
            iconType: LauncherSearchResult.IconType.Material,
            execute: () => {
                let query = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.webSearch);
                let url = Config.options.search.engineBaseUrl + query;
                for (let site of Config.options.search.excludedSites) {
                    url += ` -site:${site}`;
                }
                Qt.openUrlExternally(url);
            }
        });
        const launcherActionObjects = root.allActions.map(action => {
            const actionString = `${Config.options.search.prefix.action}${action.action}`;
            if (actionString.startsWith(root.query) || root.query.startsWith(actionString)) {
                return resultComp.createObject(null, {
                    name: root.query.startsWith(actionString) ? root.query : actionString,
                    verb: Translation.tr("Run"),
                    type: Translation.tr("Action"),
                    iconName: 'settings_suggest',
                    iconType: LauncherSearchResult.IconType.Material,
                    execute: () => {
                        action.execute(root.query.split(" ").slice(1).join(" "));
                    }
                });
            }
            return null;
        }).filter(Boolean);

        //////// Prioritized by prefix /////////
        let result = [];
        const startsWithNumber = /^\d/.test(root.query);
        const startsWithMathPrefix = root.query.startsWith(Config.options.search.prefix.math);
        const startsWithShellCommandPrefix = root.query.startsWith(Config.options.search.prefix.shellCommand);
        const startsWithWebSearchPrefix = root.query.startsWith(Config.options.search.prefix.webSearch);
        if (startsWithNumber || startsWithMathPrefix) {
            result.push(mathResultObject);
        } else if (startsWithShellCommandPrefix) {
            result.push(commandResultObject);
        } else if (startsWithWebSearchPrefix) {
            result.push(webSearchResultObject);
        }

        //////// One kind only (search modes) ////////
        if (root.mode === "apps") return result.concat(appResultObjects);
        if (root.mode === "files") return result.concat(fileResultObjects);
        if (root.mode === "windows") return result.concat(windowResults);
        if (root.mode === "settings") return result.concat(settingsResults);
        if (root.mode === "commands") {
            result = result.concat(launcherActionObjects);
            if (!startsWithShellCommandPrefix) result.push(commandResultObject);
            if (!startsWithNumber && !startsWithMathPrefix) result.push(mathResultObject);
            if (!startsWithWebSearchPrefix) result.push(webSearchResultObject);
            return result;
        }

        //////// All: the best few of each kind ////////
        result = result.concat(appResultObjects.slice(0, 5));
        result = result.concat(windowResults.slice(0, 2));
        result = result.concat(settingsResults.slice(0, 3));
        ////////// Launcher actions ////////////
        result = result.concat(launcherActionObjects);

        /// Math result, command, web search ///
        if (Config.options.search.prefix.showDefaultActionsWithoutPrefix) {
            if (!startsWithShellCommandPrefix)
                result.push(commandResultObject);
            if (!startsWithNumber && !startsWithMathPrefix)
                result.push(mathResultObject);
            if (!startsWithWebSearchPrefix)
                result.push(webSearchResultObject);
        }
        // files arrive a moment later (scripts/search/files.py): at the end, so the rows above don't move under the
        // pointer when they come in (2026-10-16)
        result = result.concat(fileResultObjects.slice(0, 3));
        
        return result;
    }

    Component {
        id: resultComp
        LauncherSearchResult {}
    }
}
