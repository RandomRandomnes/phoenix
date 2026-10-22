import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Progress and result of a background job (services/Tasks.qml), Phoenix 2026-10-16: shown where the job was started
// (Settings › Update…) instead of a terminal window. Hidden when there is no such job.
WSection {
    id: root
    required property string jobId
    readonly property var job: Tasks.jobs[root.jobId] ?? null
    property bool showLog: false
    visible: root.job !== null && !(root.job.flags ?? []).includes("needmode")

    WCard {
        icon: !root.job ? "" : root.job.running ? "progress_activity" : root.job.ok ? "check_circle" : "error"
        title: !root.job ? "" : root.job.running ? `${root.job.title}: ${root.job.step || "starting"}…`
            : root.job.ok ? `${root.job.title}: done` : `${root.job.title}: needs attention`
        description: !root.job ? "" : root.job.running ? (root.job.log.filter(l => !l.startsWith("==>")).slice(-1)[0] ?? "")
            : (root.job.msgs.length > 0 ? root.job.msgs.join("\n") : root.job.ok ? "Finished" : `Stopped (exit code ${root.job.exitCode}): see Details`)
        WButton {
            buttonText: root.showLog ? "Hide details" : "Details"
            onClicked: root.showLog = !root.showLog
        }
        WButton {
            visible: !!root.job && !root.job.running && root.job.relogin
            accent: true
            buttonText: "Sign out"
            onClicked: { GlobalStates.settingsOpen = false; GlobalStates.sessionOpen = true; }
        }
        WButton {
            visible: !!root.job && !root.job.running && root.job.reboot && !root.job.relogin
            accent: true
            buttonText: "Restart"
            onClicked: { GlobalStates.settingsOpen = false; GlobalStates.sessionOpen = true; }
        }
        WButton {
            visible: !!root.job && !root.job.running
            buttonText: "Close"
            onClicked: Tasks.clear(root.jobId)
        }
    }
    Rectangle {
        visible: root.showLog && !!root.job
        Layout.fillWidth: true
        implicitHeight: Math.min(260, logText.implicitHeight + 20)
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer2
        clip: true
        StyledFlickable {
            anchors.fill: parent
            anchors.margins: 10
            contentHeight: logText.implicitHeight
            contentY: Math.max(0, logText.implicitHeight - height)   // follows the newest lines
            StyledText {
                id: logText
                width: parent.width
                wrapMode: Text.WrapAnywhere
                text: (root.job?.log ?? []).slice(-60).join("\n")
                font.family: Appearance.font.family.monospace
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnLayer2
            }
        }
    }
}
