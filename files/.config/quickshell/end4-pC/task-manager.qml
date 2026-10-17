//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Phoenix Task Manager as its own program: only used when the desktop shell isn't running (phoenix-task-manager falls
// back to `qs -p` on this file). Normally the Task Manager is a window of the shell (modules/ii/taskManager), which
// opens instantly with the shell's theme, icons and live data. The content is shared: TaskManagerContent.qml.
import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.ii.taskManager

ApplicationWindow {
    visible: true
    title: "Task Manager"
    width: Math.min(1240, (Screen.width || 1920) - 40)
    height: Math.min(820, (Screen.height || 1080) - 120)
    minimumWidth: 860
    minimumHeight: 560
    color: Appearance.m3colors.m3background
    Component.onCompleted: MaterialThemeLoader.reapplyTheme()
    TaskManagerContent {
        anchors.fill: parent
        startPage: Quickshell.env("TASK_MANAGER_PAGE") ?? ""
    }
}
