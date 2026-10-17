pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io

Item {
    id: root
    required property var screen

    function matches(e, id) { return AppSearch.entryFor(id) === e; }
    // Which apps to show: Settings > Personalization > Super menu apps (Config.options.overview.appGrid*)
    // Each entry: { app, key }; key is what gets saved when the apps are dragged into a new order.
    readonly property var entries: {
        const o = Config.options.overview;
        const all = AppSearch.list;
        if (!o.appGridShowAll)
            return o.appGridApps.map(id => ({ app: all.find(e => matches(e, id)), key: id })).filter(x => x.app);
        const shown = all.filter(e => !o.appGridHidden.some(id => matches(e, id)));
        const rank = e => {
            const i = o.appGridOrder.findIndex(id => matches(e, id));
            return i < 0 ? o.appGridOrder.length : i;
        };
        return shown.map((e, i) => ({ app: e, key: e.id, r: rank(e), i: i }))
            .sort((a, b) => a.r - b.r || a.i - b.i);
    }

    readonly property int cellWidth: 92
    readonly property int cellHeight: 104
    readonly property int cellSpacing: 16
    readonly property int columns: Math.max(1, Math.min(8, entries.length))

    // The grid shows appModel, not entries directly: a JS array model rebuilds every icon on any change (all of them
    // replay the fade-in, which flashed after each drop). appModel only gets moves, so a reorder keeps the icons alive.
    readonly property var appByKey: {
        const m = {};
        for (const x of entries) m[x.key] = x.app;
        return m;
    }
    ListModel { id: appModel }
    function syncModel() {
        const keys = entries.map(x => x.key);
        const cur = [];
        for (let i = 0; i < appModel.count; i++) cur.push(appModel.get(i).key);
        if (cur.length !== keys.length || !keys.every(k => cur.includes(k))) {
            appModel.clear();
            for (const k of keys) appModel.append({ key: k });
            return;
        }
        for (let i = 0; i < keys.length; i++) {
            if (cur[i] === keys[i]) continue;
            const j = cur.indexOf(keys[i], i + 1);
            appModel.move(j, i, 1);
            cur.splice(i, 0, cur.splice(j, 1)[0]);
        }
    }
    onEntriesChanged: syncModel()
    Component.onCompleted: { syncModel(); root.refreshFiles(); }

    // Drag state: the app at dragFrom is shown at slot dragTo, the others shift to make room.
    property int dragFrom: -1
    property int dragTo: -1
    // True while a drop is saved: icons jump (no slide) so the model move and drag-state reset can't animate through stale slots.
    property bool committing: false

    function slotOf(i) {
        if (dragFrom < 0) return i;
        if (i === dragFrom) return dragTo;
        if (dragFrom < dragTo && i > dragFrom && i <= dragTo) return i - 1;
        if (dragFrom > dragTo && i >= dragTo && i < dragFrom) return i + 1;
        return i;
    }
    function slotX(s) { return (s % columns) * (cellWidth + cellSpacing); }
    function slotY(s) { return Math.floor(s / columns) * (cellHeight + cellSpacing); }
    function slotAt(px, py) {
        const c = Math.max(0, Math.min(columns - 1, Math.floor((px + cellSpacing / 2) / (cellWidth + cellSpacing))));
        const r = Math.max(0, Math.floor((py + cellSpacing / 2) / (cellHeight + cellSpacing)));
        return Math.min(entries.length - 1, r * columns + c);
    }
    function commitDrag() {
        const from = dragFrom, to = dragTo;
        committing = true;
        if (from >= 0 && from !== to)
            appModel.move(from, to, 1); // the config write below then finds the model already in order
        dragFrom = -1;
        dragTo = -1;
        committing = false;
        if (from < 0 || from === to) return;
        const keys = entries.map(x => x.key);
        keys.splice(to, 0, keys.splice(from, 1)[0]);
        const o = Config.options.overview;
        if (o.appGridShowAll) {
            o.appGridOrder = keys;
        } else {
            // Ids whose app isn't installed right now keep their place; the shown ones fill the other spots in the new order.
            let k = 0;
            o.appGridApps = o.appGridApps.map(id => keys.includes(id) ? keys[k++] : id);
        }
    }

    // ── Apps / Recent / Pinned tabs (P14, 2026-10-16) ──
    property string tab: "apps"
    property var recent: []           // [{path, name, dir, isDir, when}] (scripts/search/files.py items)
    property var pinned: []           // [{path, name, dir, isDir, exists}] for Config overview.pinnedItems
    readonly property var pinnedPaths: Config.options.overview.pinnedItems
    readonly property var recentShown: root.recent.filter(f => !Config.options.overview.recentHidden.includes(f.path))
    readonly property var fileRows: root.tab === "recent" ? root.recentShown : root.tab === "pinned" ? root.pinned : []
    function refreshFiles() {
        itemsProc.command = ["python3", Quickshell.shellPath("scripts/search/files.py"), "items"].concat(root.pinnedPaths);
        itemsProc.running = true;
    }
    onPinnedPathsChanged: refreshFiles()
    Process {
        id: itemsProc
        stdout: StdioCollector {
            onStreamFinished: {
                try { const d = JSON.parse(text); root.recent = d.recent ?? []; root.pinned = d.pinned ?? []; } catch (e) {}
            }
        }
    }
    function isPinned(path) { return root.pinnedPaths.includes(path) }
    function togglePin(path) {
        const o = Config.options.overview;
        o.pinnedItems = root.isPinned(path) ? o.pinnedItems.filter(p => p !== path) : o.pinnedItems.concat([path]);
    }
    function openFile(f) {
        GlobalStates.overviewOpen = false;
        if (f.isDir) Quickshell.execDetached([`${Quickshell.env("HOME")}/.local/bin/phoenix-open`, "files", f.path]);
        else Quickshell.execDetached(["xdg-open", f.path]);
    }
    function folderOf(path) { return path.substring(0, path.lastIndexOf("/")) || "/" }
    function fileIcon(f) {
        if (f.isDir) return "folder";
        const ext = (f.name.split(".").pop() ?? "").toLowerCase();
        if (["png", "jpg", "jpeg", "webp", "gif", "svg", "bmp", "heic"].includes(ext)) return "image";
        if (["mp4", "mkv", "webm", "mov", "avi"].includes(ext)) return "movie";
        if (["mp3", "flac", "ogg", "wav", "m4a", "opus"].includes(ext)) return "music_note";
        if (ext === "pdf") return "picture_as_pdf";
        if (["zip", "tar", "gz", "xz", "zst", "7z", "rar"].includes(ext)) return "folder_zip";
        if (["py", "sh", "qml", "js", "lua", "c", "cpp", "rs", "json", "toml"].includes(ext)) return "code";
        return "description";
    }
    function ago(iso) {
        const t = Date.parse(iso);
        if (isNaN(t)) return "";
        const m = Math.round((Date.now() - t) / 60000);
        if (m < 1) return Translation.tr("just now");
        if (m < 60) return Translation.tr("%1 min ago").arg(m);
        const h = Math.round(m / 60);
        if (h < 24) return Translation.tr("%1 h ago").arg(h);
        const d = Math.round(h / 24);
        return d === 1 ? Translation.tr("yesterday") : Translation.tr("%1 days ago").arg(d);
    }

    // ── Right-click menu (2026-10-16) ──
    property var menuFile: null      // a file or folder row of the Recent / Pinned tabs
    property var menuApp: null       // DesktopEntry the menu is for
    property bool uninstallArmed: false
    onMenuAppChanged: uninstallArmed = false
    property string menuKey: ""
    function launch(app) {
        NewApps.opened(app.id);
        if (app.runInTerminal)
            Quickshell.execDetached(["bash", "-c", `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(app.command.join(" "))}'`]);
        else
            app.execute();
        GlobalStates.overviewOpen = false;
    }
    function openMenu(delegate, key, app) {
        if (!app) return;
        root.menuApp = app;
        root.menuKey = key;
        const p = delegate.mapToItem(gridBackground, delegate.width / 2, delegate.height * 0.7);
        appMenu.place(p.x, p.y, delegate.mapToItem(gridBackground, 0, 0).y);
    }
    function closeMenu() { root.menuApp = null; root.menuFile = null; }
    function openFileMenu(delegate, f) {
        root.menuApp = null;
        root.menuFile = f;
        const p = delegate.mapToItem(gridBackground, Math.min(delegate.width - 60, 240), delegate.height * 0.7);
        appMenu.place(p.x, p.y, delegate.mapToItem(gridBackground, 0, 0).y);
    }
    readonly property var fileMenuItems: {
        const f = root.menuFile;
        if (!f) return [];
        const l = [{ icon: "open_in_new", text: Translation.tr("Open"), act: () => root.openFile(f) }];
        if (!f.isDir)
            l.push({ icon: "folder_open", text: Translation.tr("Open the folder"), act: () => root.openFile({ path: root.folderOf(f.path), isDir: true }) });
        l.push({ sep: true });
        const pin = root.isPinned(f.path);
        l.push({ icon: pin ? "keep_off" : "keep", text: pin ? Translation.tr("Unpin") : Translation.tr("Pin"), act: () => root.togglePin(f.path) });
        if (root.tab === "recent")
            l.push({ icon: "visibility_off", text: Translation.tr("Remove from this list"), act: () => {
                const o = Config.options.overview;
                o.recentHidden = o.recentHidden.concat([f.path]).slice(-200);
            } });
        l.push({ icon: "content_copy", text: Translation.tr("Copy the path"), act: () => Quickshell.clipboardText = f.path });
        return l;
    }
    readonly property string autostartCmd: menuApp ? `gtk-launch ${menuApp.id}` : ""
    readonly property bool menuAppStarts: Config.options.hyprland.autostartApps.apps.some(a => a.cmd === root.autostartCmd)
    readonly property var menuItems: {
        const app = root.menuApp;
        if (!app) return [];
        const l = [{ icon: "open_in_new", text: Translation.tr("Open"), act: () => root.launch(app) }];
        for (const a of (app.actions ?? []))
            l.push({ icon: "chevron_right", text: a.name, act: () => { NewApps.opened(app.id); a.execute(); GlobalStates.overviewOpen = false; } });
        l.push({ sep: true });
        const pinned = TaskbarApps.isPinned(app.id);
        l.push({ icon: pinned ? "keep_off" : "keep", text: pinned ? Translation.tr("Unpin from taskbar") : Translation.tr("Pin to taskbar"),
                 act: () => TaskbarApps.togglePin(app.id) });
        l.push({ icon: root.menuAppStarts ? "do_not_disturb_on" : "rocket_launch",
                 text: root.menuAppStarts ? Translation.tr("Don't start when I sign in") : Translation.tr("Start when I sign in"),
                 act: () => {
                     const as = Config.options.hyprland.autostartApps;
                     const cur = as.apps.filter(a => a.cmd && a.cmd.trim().length > 0);
                     if (root.menuAppStarts) as.apps = cur.filter(a => a.cmd !== root.autostartCmd);
                     else { as.apps = cur.concat([{ cmd: root.autostartCmd, delay: 0, workspace: 1 }]); as.enable = true; }
                 } });
        l.push({ icon: "visibility_off", text: Translation.tr("Remove from Super menu"), act: () => {
            const o = Config.options.overview;
            NewApps.opened(app.id);
            if (o.appGridShowAll) o.appGridHidden = o.appGridHidden.concat([root.menuKey]);
            else o.appGridApps = o.appGridApps.filter(id => id !== root.menuKey);
        } });
        l.push({ sep: true });
        l.push({ icon: "settings", text: Translation.tr("App settings"), act: () => {
            GlobalStates.overviewOpen = false;
            Quickshell.execDetached([`${Quickshell.env("HOME")}/.local/bin/phoenix-open`, "settings", "apps", "installed"]);
        } });
        // two clicks: the first asks, the second uninstalls (a background job with a notification)
        l.push({ icon: "delete", danger: true, keepOpen: !root.uninstallArmed,
                 text: root.uninstallArmed ? Translation.tr("Click again to uninstall") : Translation.tr("Uninstall"),
                 act: () => {
                     if (!root.uninstallArmed) { root.uninstallArmed = true; return; }
                     GlobalStates.overviewOpen = false; AppSearch.uninstall(app);
                 } });
        return l;
    }
    Connections {
        target: GlobalStates
        function onOverviewOpenChanged() { if (!GlobalStates.overviewOpen) { root.closeMenu(); root.tab = "apps"; } }
    }

    implicitWidth: gridBackground.implicitWidth + Appearance.sizes.elevationMargin * 2
    implicitHeight: gridBackground.implicitHeight + Appearance.sizes.elevationMargin * 2

    StyledRectangularShadow {
        target: gridBackground
    }

    Rectangle {
        id: gridBackground
        property real padding: 24
        anchors.margins: Appearance.sizes.elevationMargin
        anchors.centerIn: parent
        implicitWidth: Math.max(grid.width, 460) + padding * 2
        // the same height on every tab (the panel doesn't jump), tall enough for the right-click menu
        readonly property real contentH: Math.max(grid.height, 3 * 52)
        implicitHeight: Math.max(padding * 2 + tabRow.height + 14 + contentH, appMenu.visible ? appMenu.height + 16 : 0)
        radius: Appearance.rounding.large
        color: Appearance.colors.colLayer0

        Row {
            id: tabRow
            anchors { top: parent.top; topMargin: gridBackground.padding - 6; left: grid.left }
            spacing: 6
            Repeater {
                model: [
                    { id: "apps", name: Translation.tr("Apps"), icon: "apps" },
                    { id: "recent", name: Translation.tr("Recent"), icon: "history" },
                    { id: "pinned", name: Translation.tr("Pinned"), icon: "keep" },
                ]
                RippleButton {
                    id: tabChip
                    required property var modelData
                    toggled: root.tab === modelData.id
                    implicitHeight: 32
                    horizontalPadding: 12
                    buttonRadius: 16
                    border: !toggled
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    onClicked: { root.closeMenu(); root.tab = modelData.id; if (modelData.id !== "apps") root.refreshFiles(); }
                    contentItem: RowLayout {
                        spacing: 6
                        MaterialSymbol {
                            text: tabChip.modelData.icon
                            iconSize: Appearance.font.pixelSize.normal
                            color: tabChip.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant
                        }
                        StyledText {
                            text: tabChip.modelData.name
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: tabChip.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurface
                        }
                    }
                }
            }
        }

        // Recent / Pinned: a list in the grid's place
        ListView {
            id: fileList
            visible: root.tab !== "apps"
            anchors { top: tabRow.bottom; topMargin: 14; horizontalCenter: parent.horizontalCenter }
            width: Math.max(grid.width, 460)
            height: gridBackground.contentH
            clip: true
            spacing: 2
            model: root.fileRows
            delegate: RippleButton {
                id: fileRow
                required property var modelData
                width: fileList.width
                implicitHeight: 50
                buttonRadius: Appearance.rounding.normal
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer1Hover
                opacity: fileRow.modelData.exists === false ? 0.5 : 1
                altAction: () => root.openFileMenu(fileRow, fileRow.modelData)
                onClicked: { if (fileRow.modelData.exists !== false) root.openFile(fileRow.modelData) }
                contentItem: RowLayout {
                    spacing: 12
                    MaterialSymbol {
                        Layout.leftMargin: 8
                        text: root.fileIcon(fileRow.modelData)
                        iconSize: Appearance.font.pixelSize.huge
                        color: Appearance.colors.colPrimary
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        StyledText {
                            Layout.fillWidth: true
                            text: fileRow.modelData.name
                            elide: Text.ElideMiddle
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer0
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: fileRow.modelData.exists === false ? Translation.tr("Not found (moved or deleted)")
                                : [fileRow.modelData.dir, root.tab === "recent" ? root.ago(fileRow.modelData.when) : ""].filter(x => x).join(" · ")
                            elide: Text.ElideMiddle
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                    }
                    MaterialSymbol {
                        visible: root.tab === "recent" && root.isPinned(fileRow.modelData.path)
                        Layout.rightMargin: 10
                        text: "keep"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colSubtext
                    }
                }
            }
            StyledText {
                anchors.centerIn: parent
                visible: fileList.count === 0
                horizontalAlignment: Text.AlignHCenter
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.small
                text: root.tab === "recent" ? Translation.tr("Files you open show up here")
                    : Translation.tr("Nothing pinned yet. Right-click a recent file, or a file in search, and choose Pin")
            }
        }

        Item {
            id: grid
            visible: root.tab === "apps"
            anchors { top: tabRow.bottom; topMargin: 14; horizontalCenter: parent.horizontalCenter }
            // 8 columns max; narrower when fewer apps are shown, so short lists stay centered in the panel.
            width: root.columns * (root.cellWidth + root.cellSpacing) - root.cellSpacing
            height: Math.max(1, Math.ceil(root.entries.length / root.columns)) * (root.cellHeight + root.cellSpacing) - root.cellSpacing

            Repeater {
                model: appModel
                delegate: MouseArea {
                    id: appDelegate
                    required property string key
                    required property int index
                    readonly property var app: root.appByKey[key] ?? null
                    readonly property bool dragging: root.dragFrom === index
                    property point pressPos
                    property point grabOffset
                    property bool wasDragged: false
                    width: root.cellWidth
                    height: root.cellHeight
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                    preventStealing: true
                    z: dragging ? 10 : 0

                    // Slot position; while dragged it follows the pointer instead.
                    x: root.slotX(root.slotOf(index))
                    y: root.slotY(root.slotOf(index))
                    Behavior on x {
                        enabled: !appDelegate.dragging && !root.committing
                        NumberAnimation {
                            duration: Appearance.animation.elementMoveSmall.duration
                            easing.type: Appearance.animation.elementMoveSmall.type
                            easing.bezierCurve: Appearance.animation.elementMoveSmall.bezierCurve
                        }
                    }
                    Behavior on y {
                        enabled: !appDelegate.dragging && !root.committing
                        NumberAnimation {
                            duration: Appearance.animation.elementMoveSmall.duration
                            easing.type: Appearance.animation.elementMoveSmall.type
                            easing.bezierCurve: Appearance.animation.elementMoveSmall.bezierCurve
                        }
                    }

                    opacity: 0
                    scale: 0.85
                    transformOrigin: Item.Center

                    Component.onCompleted: entranceAnim.start()

                    SequentialAnimation {
                        id: entranceAnim
                        PauseAnimation { duration: Math.max(0, Math.min(appDelegate.index * 12, 300)) }
                        ParallelAnimation {
                            NumberAnimation {
                                target: appDelegate
                                property: "opacity"
                                to: 1
                                duration: Appearance.animation.elementMoveEnter.duration
                                easing.type: Appearance.animation.elementMoveEnter.type
                                easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                            }
                            NumberAnimation {
                                target: appDelegate
                                property: "scale"
                                to: appDelegate.containsMouse ? 1.08 : 1.0
                                duration: Appearance.animation.elementMoveEnter.duration
                                easing.type: Appearance.animation.elementMoveEnter.type
                                easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                            }
                        }
                    }

                    Behavior on scale {
                        enabled: !entranceAnim.running
                        NumberAnimation {
                            duration: Appearance.animation.elementMoveSmall.duration
                            easing.type: Appearance.animation.elementMoveSmall.type
                            easing.bezierCurve: Appearance.animation.elementMoveSmall.bezierCurve
                        }
                    }

                    onContainsMouseChanged: {
                        if (!entranceAnim.running && !dragging)
                            scale = containsMouse ? 1.08 : 1.0
                    }
                    onPressed: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            root.openMenu(appDelegate, appDelegate.key, appDelegate.app);
                            return;
                        }
                        if (root.menuApp) { root.closeMenu(); mouse.accepted = false; return; }
                        pressPos = Qt.point(mouse.x, mouse.y);
                        wasDragged = false;
                        grabOffset = Qt.point(mouse.x, mouse.y);
                        if (!entranceAnim.running) scale = 0.92;
                    }
                    onPositionChanged: mouse => {
                        if (!pressed) return;
                        if (!dragging) {
                            if (Math.hypot(mouse.x - pressPos.x, mouse.y - pressPos.y) < 10) return;
                            wasDragged = true;
                            entranceAnim.stop();
                            opacity = 1;
                            scale = 1.12;
                            root.dragTo = index;
                            root.dragFrom = index;
                        }
                        const p = mapToItem(grid, mouse.x, mouse.y);
                        x = p.x - grabOffset.x;
                        y = p.y - grabOffset.y;
                        root.dragTo = root.slotAt(x + width / 2 - root.cellWidth / 2, y + height / 2 - root.cellHeight / 2);
                    }
                    onReleased: {
                        if (dragging) {
                            root.commitDrag();
                            // Rebind to the slot (the saved order rebuilds the grid anyway).
                            x = Qt.binding(() => root.slotX(root.slotOf(index)));
                            y = Qt.binding(() => root.slotY(root.slotOf(index)));
                        }
                        if (!entranceAnim.running) scale = containsMouse ? 1.08 : 1.0;
                    }
                    onCanceled: {
                        if (dragging) {
                            root.dragFrom = -1;
                            root.dragTo = -1;
                            x = Qt.binding(() => root.slotX(root.slotOf(index)));
                            y = Qt.binding(() => root.slotY(root.slotOf(index)));
                        }
                        scale = 1.0;
                    }

                    onClicked: mouse => {
                        // A drag ends with a release too; only launch on a real click.
                        if (wasDragged || mouse.button !== Qt.LeftButton) return;
                        root.launch(app);
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 6
                        IconImage {
                            Layout.alignment: Qt.AlignHCenter
                            implicitSize: 52
                            source: AppSearch.iconPath(appDelegate.app?.icon ?? "", "image-missing")
                            // newly installed (services/NewApps.qml): a dot until it's opened once
                            Rectangle {
                                visible: NewApps.isNew(appDelegate.app?.id ?? "")
                                anchors { top: parent.top; right: parent.right; topMargin: -2; rightMargin: -2 }
                                width: 12; height: 12; radius: 6
                                color: Appearance.colors.colPrimary
                                border.width: 2
                                border.color: Appearance.colors.colLayer0
                            }
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: 88
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: appDelegate.app?.name ?? ""
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }

        // clicks anywhere else in the panel close the menu
        MouseArea {
            anchors.fill: parent
            visible: appMenu.visible
            z: 99
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onPressed: root.closeMenu()
        }

        Rectangle {
            id: appMenu
            visible: root.menuApp !== null || root.menuFile !== null
            z: 100
            width: 280
            height: menuColumn.implicitHeight + 12
            radius: Appearance.rounding.normal
            color: Appearance.m3colors.m3surfaceContainerHigh   // solid: the grid mustn't show through
            border.width: 1
            border.color: Appearance.colors.colOutlineVariant
            // where it was opened; x/y follow its real size (the rows load a moment after it opens)
            property real px: 0
            property real py: 0
            property real cellTop: 0
            function place(ax, ay, top) { px = ax; py = ay; cellTop = top; }
            readonly property real panelH: gridBackground.padding * 2 + tabRow.height + 14 + gridBackground.contentH
            x: Math.max(8, Math.min(gridBackground.width - width - 8, px - 20))
            // below the pointer if it fits, else above the icon, else as low as the panel allows
            y: py + height + 8 <= Math.max(panelH, height + 16) ? py
                : Math.max(8, Math.min(cellTop - height + 8, Math.max(panelH, height + 16) - height - 8))
            opacity: visible ? 1 : 0
            scale: visible ? 1 : 0.95
            transformOrigin: Item.TopLeft
            Behavior on opacity { NumberAnimation { duration: 120 } }
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            ColumnLayout {
                id: menuColumn
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }
                spacing: 0
                StyledText {
                    Layout.fillWidth: true
                    Layout.margins: 8
                    Layout.bottomMargin: 4
                    text: root.menuApp?.name ?? root.menuFile?.name ?? ""
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer2
                }
                Repeater {
                    model: root.menuFile ? root.fileMenuItems : root.menuItems
                    delegate: Loader {
                        id: row
                        required property var modelData
                        Layout.fillWidth: true
                        sourceComponent: modelData.sep ? sepComp : itemComp
                        Component {
                            id: sepComp
                            Rectangle { implicitHeight: 9; color: "transparent"
                                Rectangle { anchors.centerIn: parent; width: parent.width - 12; height: 1; color: Appearance.colors.colOutlineVariant } }
                        }
                        Component {
                            id: itemComp
                            RippleButton {
                                implicitHeight: 34
                                buttonRadius: Appearance.rounding.small
                                colBackground: "transparent"
                                colBackgroundHover: Appearance.colors.colLayer2Hover
                                onClicked: { const act = row.modelData.act; if (!row.modelData.keepOpen) root.closeMenu(); act(); }
                                contentItem: RowLayout {
                                    spacing: 10
                                    MaterialSymbol {
                                        Layout.leftMargin: 6
                                        text: row.modelData.icon
                                        iconSize: Appearance.font.pixelSize.larger
                                        color: row.modelData.danger ? Appearance.colors.colError : Appearance.colors.colOnLayer2
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: row.modelData.text
                                        elide: Text.ElideRight
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: row.modelData.danger ? Appearance.colors.colError : Appearance.colors.colOnLayer2
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
