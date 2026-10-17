import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.panels.lock

// The password field of the Phoenix lock screen styles (2026-10-15): text only, no background (each style draws its
// own). Synchronised with the LockContext like illogical-impulse's field: typing on one screen shows on all of them.
Item {
    id: root
    required property LockContext context
    property color textColor: Appearance.colors.colOnLayer1
    property color placeholderColor: Appearance.colors.colSubtext
    property string fontFamily: Appearance.font.family.main
    property real fontSize: Appearance.font.pixelSize.normal
    property int horizontalAlignment: TextInput.AlignLeft
    property string placeholder: Translation.tr("Password")
    property string passwordCharacter: "●"
    property real letterSpacing: 2
    property bool ctrlHeld: false                 // Ctrl+Enter: unlock and keep the PC awake (illogical-impulse)
    property bool preview: false                  // the preview (modules/ii/lock/LockPreview.qml): Enter only clears, nothing is checked
    signal accepted()
    readonly property alias textInput: input       // e.g. for illogical-impulse's shape dots drawn over the field

    implicitWidth: 240
    implicitHeight: Math.max(input.implicitHeight, 24)

    function focusField() { input.forceActiveFocus(); }

    TextInput {
        id: input
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        color: root.textColor
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
        font.letterSpacing: root.letterSpacing
        horizontalAlignment: root.horizontalAlignment
        echoMode: TextInput.Password
        passwordCharacter: root.passwordCharacter
        passwordMaskDelay: 0
        inputMethodHints: Qt.ImhSensitiveData
        selectByMouse: false
        enabled: !root.context.unlockInProgress
        selectionColor: "transparent"
        selectedTextColor: root.textColor

        onTextChanged: root.context.currentText = text
        onAccepted: {
            root.accepted();
            if (root.preview) { root.context.clearText(); return; }
            root.context.tryUnlock(root.ctrlHeld);
        }
        Keys.onPressed: event => root.context.resetClearTimer()
        Connections {
            target: root.context
            function onCurrentTextChanged() {
                if (input.text !== root.context.currentText) input.text = root.context.currentText;
            }
        }
    }

    // placeholder, or why the last try failed (wrong password, too many attempts)
    StyledText {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: input.text.length === 0
        horizontalAlignment: root.horizontalAlignment === TextInput.AlignHCenter ? Text.AlignHCenter
            : root.horizontalAlignment === TextInput.AlignRight ? Text.AlignRight : Text.AlignLeft
        elide: Text.ElideRight
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
        color: GlobalStates.screenUnlockFailed ? Appearance.colors.colError : root.placeholderColor
        text: root.context.unlockInProgress ? Translation.tr("Checking…")
            : GlobalStates.screenUnlockFailed ? (root.context.failureMessage || Translation.tr("Incorrect password"))
            : root.context.targetAction === LockContext.ActionEnum.Poweroff ? Translation.tr("Password to shut down")
            : root.context.targetAction === LockContext.ActionEnum.Reboot ? Translation.tr("Password to restart")
            : root.context.targetAction === LockContext.ActionEnum.SwitchUser ? Translation.tr("Password to switch user")
            : root.placeholder
    }

    // shake on a wrong password, like illogical-impulse's field (its ErrorShakeAnimation needs a layout; this doesn't)
    transform: Translate { id: shakeShift }
    SequentialAnimation {
        id: shake
        NumberAnimation { target: shakeShift; property: "x"; to: -24; duration: 50 }
        NumberAnimation { target: shakeShift; property: "x"; to: 24; duration: 50 }
        NumberAnimation { target: shakeShift; property: "x"; to: -12; duration: 40 }
        NumberAnimation { target: shakeShift; property: "x"; to: 12; duration: 40 }
        NumberAnimation { target: shakeShift; property: "x"; to: 0; duration: 30 }
    }
    Connections {
        target: GlobalStates
        function onScreenUnlockFailedChanged() {
            if (GlobalStates.screenUnlockFailed) shake.restart();
        }
    }
}
