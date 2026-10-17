//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Quick Start as its own program: only used when the desktop shell isn't running (`phoenix-open quickstart` falls back
// to `qs -p` on this file). Normally it is a window of the shell (modules/ii/quickStart). Content: QuickStartContent.qml.
import QtQuick
import QtQuick.Controls
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.ii.quickStart

ApplicationWindow {
    visible: true
    title: "Phoenix Quick Start"
    width: 980
    height: 700
    minimumWidth: 720
    minimumHeight: 480
    color: Appearance.m3colors.m3background
    Component.onCompleted: MaterialThemeLoader.reapplyTheme()
    QuickStartContent {
        anchors.fill: parent
        startPage: Quickshell.env("QUICK_START_PAGE") ?? ""
        onDone: Qt.quit()
    }
}
