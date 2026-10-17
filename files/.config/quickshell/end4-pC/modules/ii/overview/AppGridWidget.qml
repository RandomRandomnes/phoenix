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
    Component.onCompleted: syncModel()

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

    // ── Right-click menu (2026-10-16) ──
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
    function closeMenu() { root.menuApp = null; }
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
        function onOverviewOpenChanged() { if (!GlobalStates.overviewOpen) root.closeMenu(); }
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
        implicitWidth: grid.width + padding * 2
        implicitHeight: Math.max(grid.height + padding * 2, appMenu.visible ? appMenu.height + 16 : 0)
        radius: Appearance.rounding.large
        color: Appearance.colors.colLayer0

        Item {
            id: grid
            anchors.centerIn: parent
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
            visible: root.menuApp !== null
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
            readonly property real panelH: grid.height + gridBackground.padding * 2
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
                    text: root.menuApp?.name ?? ""
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer2
                }
                Repeater {
                    model: root.menuItems
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
