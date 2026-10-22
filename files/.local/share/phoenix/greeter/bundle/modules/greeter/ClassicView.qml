import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import qs.modules.common.panels.lock

// Phoenix login screen, classic look (2026-10-08; its own file since 2026-10-22): clock, account picture, password
// pill, other accounts bottom left, desktop + power bottom right. Used for the lock style "Original" (which needs the
// whole desktop) and when a style can't be loaded. The password goes through the same LockContext as the styles.
Item {
    id: view
    required property var greeter
    required property LockContext context
    readonly property var g: greeter

    ColumnLayout {   // clock
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: parent.height * 0.12 }
        spacing: 0
        Text {
            id: clock
            Layout.alignment: Qt.AlignHCenter
            font { family: view.g.fontMain; pixelSize: 112; weight: Font.Medium }
            color: view.g.cOnWall
        }
        Text {
            id: date
            Layout.alignment: Qt.AlignHCenter
            font { family: view.g.fontMain; pixelSize: 24 }
            color: view.g.cOnWall
            opacity: 0.85
        }
        Timer {
            interval: 1000; running: true; repeat: true; triggeredOnStart: true
            onTriggered: {
                const now = new Date()
                clock.text = now.toLocaleTimeString(Qt.locale(), view.g.clockFormat)
                date.text = now.toLocaleDateString(Qt.locale(), "dddd, MMMM d")
            }
        }
    }

    ColumnLayout {   // the user and the password
        anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter; verticalCenterOffset: parent.height * 0.08 }
        spacing: 14

        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 120; implicitHeight: 120
            Rectangle {
                anchors.fill: parent
                radius: 60
                color: view.g.cAccent
                Text {
                    anchors.centerIn: parent
                    text: (view.g.user?.real || view.g.user?.name || "?").charAt(0).toUpperCase()
                    font { family: view.g.fontMain; pixelSize: 52; weight: Font.Medium }
                    color: view.g.cOnAccent
                }
            }
            Image {   // the account picture, when there is one
                id: face
                anchors.fill: parent
                // each user's own picture; the plain "face" (the last user's) only for that user (QA 2026-10-08)
                source: view.g.user ? "file://" + view.g.themeDir + "/face-" + view.g.user.name : ""
                fillMode: Image.PreserveAspectCrop
                visible: false
            }
            Rectangle { id: faceMask; anchors.fill: parent; radius: 60; visible: false; layer.enabled: true }
            MultiEffect { anchors.fill: parent; source: face; maskEnabled: true; maskSource: faceMask; visible: face.status === Image.Ready }
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: view.g.user ? (view.g.user.real || view.g.user.name) : "No users"
            font { family: view.g.fontMain; pixelSize: 30; weight: Font.Medium }
            color: view.g.cOnWall
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 340; implicitHeight: 52; radius: 26
            color: Qt.alpha(view.g.cCard, 0.9)
            border { width: passwordField.activeFocus ? 2 : 1; color: passwordField.activeFocus ? view.g.cPrimary : Qt.alpha(view.g.cText, 0.15) }
            transform: Translate { id: shakeX }
            SequentialAnimation {   // a wrong password shakes the field
                id: shake
                NumberAnimation { target: shakeX; property: "x"; to: -12; duration: 50 }
                NumberAnimation { target: shakeX; property: "x"; to: 12; duration: 70 }
                NumberAnimation { target: shakeX; property: "x"; to: -8; duration: 70 }
                NumberAnimation { target: shakeX; property: "x"; to: 0; duration: 60 }
            }
            RowLayout {
                anchors { fill: parent; leftMargin: 20; rightMargin: 6 }
                TextField {
                    id: passwordField
                    Layout.fillWidth: true
                    echoMode: TextInput.Password
                    placeholderText: "Password"
                    placeholderTextColor: view.g.cSub
                    color: view.g.cText
                    font { family: view.g.fontMain; pixelSize: 18 }
                    enabled: !view.g.busy
                    focus: true
                    background: null
                    onTextChanged: view.context.currentText = text
                    onAccepted: view.context.tryUnlock(false, false)
                    Component.onCompleted: forceActiveFocus()
                    Connections {
                        target: view.context
                        function onCurrentTextChanged() { if (passwordField.text !== view.context.currentText) passwordField.text = view.context.currentText }
                        function onShouldReFocus() { passwordField.forceActiveFocus() }
                        function onFailed() { shake.restart() }
                    }
                }
                Rectangle {
                    implicitWidth: 40; implicitHeight: 40; radius: 20
                    color: view.g.busy ? Qt.alpha(view.g.cPrimary, 0.5) : view.g.cPrimary
                    Text {
                        anchors.centerIn: parent
                        text: view.g.busy ? "hourglass_top" : "arrow_forward"
                        font { family: view.g.fontIcons; pixelSize: 24 }
                        color: view.g.cOnPrimary
                    }
                    // the arrow button still signs in with an empty password, for accounts that have none (QA 2026-10-08)
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: view.context.tryUnlock(false, true) }
                }
            }
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: 420
            visible: view.g.message !== ""
            text: view.g.message
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            font { family: view.g.fontMain; pixelSize: 16 }
            color: view.g.messageIsError ? "#ffb4ab" : view.g.cOnWall
        }
    }

    RowLayout {   // other users, bottom left
        visible: view.g.users.length > 1
        anchors { left: parent.left; bottom: parent.bottom; margins: 28 }
        spacing: 8
        Repeater {
            model: view.g.users
            Rectangle {
                required property var modelData
                required property int index
                implicitHeight: 44; implicitWidth: userLabel.implicitWidth + 32; radius: 22
                color: index === view.g.userIndex ? view.g.cAccent : Qt.alpha(view.g.cCard, 0.85)
                Text {
                    id: userLabel
                    anchors.centerIn: parent
                    text: modelData.real || modelData.name
                    font { family: view.g.fontMain; pixelSize: 16 }
                    color: index === view.g.userIndex ? view.g.cOnAccent : view.g.cText
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: view.g.pickUser(index) }
            }
        }
    }

    RowLayout {   // session and power, bottom right
        anchors { right: parent.right; bottom: parent.bottom; margins: 28 }
        spacing: 10
        Rectangle {
            visible: view.g.sessions.length > 1
            implicitHeight: 44; implicitWidth: sessionLabel.implicitWidth + 64; radius: 22
            color: Qt.alpha(view.g.cCard, 0.85)
            RowLayout {
                anchors.centerIn: parent
                spacing: 8
                Text { text: "desktop_windows"; font { family: view.g.fontIcons; pixelSize: 20 } color: view.g.cText }
                Text { id: sessionLabel; text: view.g.sessions[view.g.sessionIndex]?.name ?? ""; font { family: view.g.fontMain; pixelSize: 16 } color: view.g.cText }
            }
            MouseArea {   // click to switch between the sessions
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: view.g.sessionIndex = (view.g.sessionIndex + 1) % view.g.sessions.length
            }
        }
        Repeater {
            model: [{ icon: "restart_alt", cmd: "reboot" }, { icon: "power_settings_new", cmd: "poweroff" }]
            Rectangle {
                required property var modelData
                implicitWidth: 44; implicitHeight: 44; radius: 22
                color: Qt.alpha(view.g.cCard, 0.85)
                Text { anchors.centerIn: parent; text: modelData.icon; font { family: view.g.fontIcons; pixelSize: 22 } color: view.g.cText }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: view.g.power(modelData.cmd) }
            }
        }
    }
}
