//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF

// Windows 11 style settings window. Replaces modules/ii/settings/Settings.qml in the panel family;
// the original illogical-impulse settings were merged into these pages on 2026-10-15 (settingsW11/S*.qml).
Scope {
    id: root

    // A normal app window (2026-10-03; was a full-screen overlay that closed when you clicked anywhere else):
    // it stays open while you use other windows, and moves/closes like any other window.
    FloatingWindow {
        id: panelWindow
        visible: GlobalStates.settingsOpen
        title: "Settings"
        color: Appearance.colors.colLayer0
        // fits smaller screens (2026-10-08): on a 1280×800 screen the 820 px window hid its header (back arrow) under the bar.
        // Worked out when Settings opens (not live: it resized when focus moved to another screen), with width and height
        // swapped on a rotated (portrait) screen.
        property real monW: 1920
        property real monH: 1080
        function measure() {
            const mon = Hyprland.focusedMonitor
            const o = mon?.lastIpcObject ?? {}
            if (!mon) return
            const portrait = [1, 3, 5, 7].includes(o.transform ?? 0)
            const scale = o.scale || mon.scale || 1
            const w = (o.width ?? mon.width) / scale, h = (o.height ?? mon.height) / scale
            panelWindow.monW = portrait ? h : w
            panelWindow.monH = portrait ? w : h
        }
        implicitWidth: Math.min(1240, monW - 40)
        implicitHeight: Math.min(820, monH - 120)
        // back in Settings (focus returns to it): pages reload what they read once (WState.refreshTick)
        readonly property bool focused: GlobalStates.settingsOpen && ToplevelManager.activeToplevel?.title === "Settings"
            && ToplevelManager.activeToplevel?.appId === "org.quickshell"
        onFocusedChanged: if (focused) WState.refresh()
        // measured while Settings is closed, so the size is right before the window appears (measuring when it became
        // visible came too late: it stayed 1240×820 on an 800 px screen; QA 2026-10-09)
        Component.onCompleted: measure()
        Connections {
            target: Hyprland
            function onFocusedMonitorChanged() { if (!panelWindow.visible) panelWindow.measure() }
        }
        Connections {
            target: GlobalStates
            function onSettingsOpenChanged() { if (GlobalStates.settingsOpen) panelWindow.measure() }
        }

        function hide() {
            GlobalStates.settingsOpen = false;
        }

        onVisibleChanged: {
            if (visible) {
                win.forceActiveFocus();
            } else {
                GlobalStates.settingsOpen = false;   // closed by the window manager (title bar ✕, Super+Q)
                searchField.text = "";
            }
        }

        Rectangle {
            id: win
            anchors.fill: parent
            color: Appearance.colors.colLayer0
            clip: true
            focus: true

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    if (searchField.text.length > 0) searchField.text = "";
                    else panelWindow.hide();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Back || (event.key === Qt.Key_Left && (event.modifiers & Qt.AltModifier))) {
                    WState.back();
                    event.accepted = true;
                } else if (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)) {
                    searchField.forceActiveFocus();
                    event.accepted = true;
                }
            }

            // Phoenix (2026-10-15): "Material rail" look (concept 2): an icon rail on the left, the page in one big rounded
            // panel with an expressive title and a pill search box. Colors are the theme's (Material You).
            RowLayout {
                anchors.fill: parent
                spacing: 0

                // ── Navigation rail ─────────────────────────────────────────
                ColumnLayout {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 96
                    Layout.maximumWidth: 96
                    spacing: 0

                    // drag strip (no system title bar: hypr/custom/rules.lua "settings-no-titlebar")
                    WDragArea { Layout.fillWidth: true; implicitHeight: 16 }

                    RippleButton {   // search
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: 12
                        implicitWidth: 56
                        implicitHeight: 56
                        buttonRadius: Appearance.rounding.normal
                        colBackground: Appearance.colors.colPrimaryContainer
                        colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                        colRipple: Appearance.colors.colPrimaryContainerActive
                        onClicked: searchField.forceActiveFocus()
                        contentItem: MaterialSymbol {
                            text: "search"
                            iconSize: 24
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                        StyledToolTip { text: "Find a setting (Ctrl+F)" }
                    }

                    ListView {
                        id: navList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.bottomMargin: 8
                        clip: true
                        spacing: 2
                        boundsBehavior: Flickable.StopAtBounds
                        model: WState.categories
                        // short labels under the icons (the full name is the page title). On short windows (1280×800
                        // screens) the rail goes compact: icons only, the name as a tooltip, so every category fits.
                        readonly property bool compact: height < WState.categories.length * 54
                        readonly property var shortNames: ({ personalization: "Personalize", devices: "Devices",
                            network: "Network", time: "Time", accessibility: "Access", privacy: "Privacy" })
                        delegate: Item {
                            id: navItem
                            required property var modelData
                            readonly property bool current: WState.page === modelData.id
                            width: navList.width
                            height: navList.compact ? 40 : 52
                            MouseArea {
                                id: navMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    WState.history = [];
                                    WState.go(navItem.modelData.id);
                                    WState.history = [];
                                }
                            }
                            Rectangle {   // the pill behind the icon
                                id: pill
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: navList.compact ? 4 : 2
                                width: navItem.current ? 56 : (navMouse.containsMouse ? 56 : 32)
                                height: 32
                                radius: 16
                                color: navItem.current ? Appearance.colors.colSecondaryContainer
                                    : navMouse.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"
                                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 150 } }
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: navItem.modelData.icon
                                    iconSize: 22
                                    fill: navItem.current ? 1 : 0
                                    color: navItem.current ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer0
                                }
                            }
                            StyledToolTip {
                                text: navItem.modelData.name
                                extraVisibleCondition: navList.compact && navMouse.containsMouse
                            }
                            StyledText {
                                visible: !navList.compact
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: pill.bottom
                                anchors.topMargin: 3
                                text: navList.shortNames[navItem.modelData.id] ?? navItem.modelData.name
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: navItem.current ? Font.DemiBold : Font.Normal
                                color: navItem.current ? Appearance.colors.colOnLayer0 : Appearance.colors.colSubtext
                            }
                        }
                    }

                }

                // ── Page panel ──────────────────────────────────────────────
                Rectangle {
                    id: panel
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.topMargin: 12
                    Layout.rightMargin: 12
                    Layout.bottomMargin: 12
                    radius: Appearance.rounding.verylarge
                    color: Appearance.colors.colLayer1
                    clip: true

                    WDragArea { anchors { left: parent.left; right: parent.right; top: parent.top } height: 24 }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 36
                        anchors.rightMargin: 18
                        anchors.topMargin: 22
                        spacing: 18

                        // header: back, overline + expressive title, search, close
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.rightMargin: 4
                            spacing: 14

                            RippleButton {
                                visible: WState.canGoBack
                                Layout.alignment: Qt.AlignVCenter
                                implicitWidth: 44
                                implicitHeight: 44
                                buttonRadius: 22
                                colBackground: Appearance.colors.colLayer2
                                colBackgroundHover: Appearance.colors.colLayer2Hover
                                onClicked: WState.back()
                                contentItem: MaterialSymbol {
                                    text: "arrow_back"
                                    iconSize: 22
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    color: Appearance.colors.colOnLayer1
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                StyledText {
                                    id: crumbRoot
                                    text: WState.sub ? WState.categoryName(WState.page) : "Settings"
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colSubtext
                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: WState.sub !== ""
                                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: WState.go(WState.page, "")
                                    }
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: WState.sub ? WState.subTitle(WState.page, WState.sub) : WState.categoryName(WState.page)
                                    font.family: Appearance.font.family.expressive
                                    font.pixelSize: 40
                                    font.weight: Font.DemiBold
                                    color: Appearance.colors.colOnLayer1
                                    elide: Text.ElideRight
                                }
                            }
                            // search pill
                            Rectangle {
                                id: searchPill
                                Layout.alignment: Qt.AlignVCenter
                                implicitWidth: 300
                                implicitHeight: 48
                                radius: 24
                                color: Appearance.colors.colLayer2
                                border.width: searchField.activeFocus ? 2 : 0
                                border.color: Appearance.colors.colPrimary
                                RowLayout {
                                    anchors { fill: parent; leftMargin: 18; rightMargin: 16 }
                                    spacing: 10
                                    MaterialSymbol {
                                        text: "search"
                                        iconSize: 20
                                        color: Appearance.colors.colSubtext
                                    }
                                    TextField {
                                        id: searchField
                                        Layout.fillWidth: true
                                        placeholderText: "Find a setting"
                                        placeholderTextColor: Appearance.colors.colSubtext
                                        color: Appearance.colors.colOnLayer1
                                        font.family: Appearance.font.family.main
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        background: null
                                        selectByMouse: true
                                        Keys.onReturnPressed: {
                                            const r = searchPopup.results;
                                            if (r.length > 0) searchPopup.open(r[0]);
                                        }
                                        Keys.onEscapePressed: text = ""
                                    }
                                }
                            }
                            RippleButton {
                                Layout.alignment: Qt.AlignVCenter
                                implicitWidth: 44
                                implicitHeight: 44
                                buttonRadius: 22
                                colBackgroundHover: Appearance.colors.colErrorContainer
                                onClicked: panelWindow.hide()
                                contentItem: MaterialSymbol {
                                    text: "close"
                                    iconSize: 22
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    color: Appearance.colors.colOnLayer1
                                }
                            }
                        }

                        Loader {
                            id: pageLoader
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            active: GlobalStates.settingsOpen || item !== null
                            source: {
                                const p = WState.page;
                                return `P${p.charAt(0).toUpperCase()}${p.slice(1)}.qml`;
                            }
                            opacity: status === Loader.Ready ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        }
                    }

                    // Search results, under the search pill (solid: easier to read than the see-through layers)
                    Rectangle {
                        id: searchPopup
                        property var results: WState.search(searchField.text)
                        function open(r) {
                            searchField.text = "";
                            WState.go(r.page, r.sub, r.highlight ?? "");
                        }
                        visible: searchField.text.length > 0
                        anchors.right: parent.right
                        anchors.rightMargin: 80
                        y: 84
                        z: 10
                        width: 360
                        height: resultsCol.implicitHeight + 16
                        radius: Appearance.rounding.large
                        // solid, not the see-through layer color: the page underneath made the results hard to read (2026-10-15)
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        border.width: 1
                        border.color: Appearance.colors.colOutlineVariant

                        ColumnLayout {
                            id: resultsCol
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                            spacing: 2
                            StyledText {
                                visible: searchPopup.results.length === 0
                                Layout.margins: 12
                                text: "No results"
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.small
                            }
                            Repeater {
                                model: searchPopup.results
                                RippleButton {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 52
                                    buttonRadius: Appearance.rounding.normal
                                    onClicked: searchPopup.open(modelData)
                                    contentItem: RowLayout {
                                        spacing: 12
                                        Rectangle {
                                            Layout.leftMargin: 6
                                            implicitWidth: 36
                                            implicitHeight: 36
                                            radius: 12
                                            color: Appearance.colors.colSecondaryContainer
                                            MaterialSymbol {
                                                anchors.centerIn: parent
                                                text: WState.categories.find(c => c.id === modelData.page)?.icon ?? "tune"
                                                iconSize: 18
                                                color: Appearance.colors.colOnSecondaryContainer
                                            }
                                        }
                                        ColumnLayout {
                                            spacing: 0
                                            Layout.fillWidth: true
                                            StyledText {
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignLeft
                                                text: modelData.title
                                                font.pixelSize: Appearance.font.pixelSize.small
                                                color: Appearance.colors.colOnLayer2
                                                elide: Text.ElideRight
                                            }
                                            StyledText {
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignLeft
                                                elide: Text.ElideRight
                                                text: WState.categoryName(modelData.page) + (modelData.sub ? " › " + WState.subTitle(modelData.page, modelData.sub) : "")
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                color: Appearance.colors.colSubtext
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
    }

    IpcHandler {
        target: "settings"
        function toggle(): void { GlobalStates.settingsOpen = !GlobalStates.settingsOpen; }
        function open(): void   { GlobalStates.settingsOpen = true; }
        function close(): void  { GlobalStates.settingsOpen = false; }
        function go(page: string, sub: string): void { GlobalStates.settingsOpen = true; WState.go(page, sub); }
    }

    CompositorGlobalShortcut {
        name: "settingsToggle"
        description: "Toggles settings panel"
        onPressed: GlobalStates.settingsOpen = !GlobalStates.settingsOpen;
    }
}


