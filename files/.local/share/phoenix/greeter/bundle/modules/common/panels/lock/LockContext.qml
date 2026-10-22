import QtQuick
import Quickshell

// Phoenix login screen (2026-10-22): the lock screen styles' LockContext, with greetd behind it instead of PAM.
// The styles call tryUnlock() / unlocked(action); shell.qml signs in (signInRequested) and does the power actions.
Scope {
    id: root

    enum ActionEnum { Unlock, Poweroff, Reboot, SwitchUser }

    signal shouldReFocus()
    signal unlocked(targetAction: var)
    signal failed()
    signal signInRequested(password: string)

    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false
    property bool fingerprintsConfigured: false
    property string failureMessage: ""
    property var targetAction: LockContext.ActionEnum.Unlock
    property bool alsoInhibitIdle: false

    function resetTargetAction() { root.targetAction = LockContext.ActionEnum.Unlock; }
    function clearText() { root.currentText = ""; }
    function resetClearTimer() {}
    function reset() { root.resetTargetAction(); root.clearText(); root.unlockInProgress = false; }
    // like the lock screen: an empty Enter is no attempt (each one counts towards the lockout); the arrow button may
    // sign in with an empty password on purpose (allowEmpty)
    function tryUnlock(alsoInhibitIdle = false, allowEmpty = false) {
        if (root.unlockInProgress) return;
        if (root.currentText.length === 0 && !allowEmpty) { root.shouldReFocus(); return; }
        root.signInRequested(root.currentText);
    }
    function tryFingerUnlock() {}
    function stopFingerPam() {}
}
