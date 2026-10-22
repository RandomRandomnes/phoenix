import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.panels.lock

// Phoenix lock screen styles (2026-10-15): what every style shares, so each style file only decides the look.
// Password handling is the same as illogical-impulse's LockSurface: the text lives in the LockContext (shared by every
// screen), Enter tries PAM, an empty Enter is ignored (the arrow button may try an empty password on purpose), Ctrl+Enter
// also keeps the PC awake, Esc clears, and the power buttons follow lock.security.requirePasswordToPower.
MouseArea {
    id: root
    required property LockContext context
    property Item passwordField: null            // the style's LockPasswordInput: gets the keyboard focus
    property bool preview: false                 // the preview (modules/ii/lock/LockPreview.qml): no password check, no power actions
    // the Phoenix login screen shows these styles too (2026-10-22, ~/.local/share/phoenix/greeter): there nothing is locked yet
    readonly property bool atLogin: Config.options.lock.atLogin ?? false

    readonly property bool requirePasswordToPower: Config.options.lock.security.requirePasswordToPower
    readonly property MprisPlayer player: MprisController.activePlayer
    readonly property string trackTitle: StringUtils.cleanMusicTitle(player?.trackTitle) || ""
    readonly property string trackArtist: player?.trackArtist || ""
    readonly property string artUrl: player?.trackArtUrl ?? ""
    readonly property bool showMedia: Config.options.lock.showMedia && player !== null && trackTitle !== ""
    readonly property string username: SystemInfo.username
    readonly property string timeText: DateTime.time
    readonly property string hourText: DateTime.hourStr
    readonly property string minuteText: DateTime.minuteStr
    readonly property string weekdayText: Qt.locale().toString(DateTime.clock.date, "dddd")
    readonly property string dayMonthText: Qt.locale().toString(DateTime.clock.date, "MMMM d")
    readonly property string dateText: Qt.locale().toString(DateTime.clock.date, "dddd, MMMM d")
    readonly property string statusText: GlobalStates.screenUnlockFailed
        ? (context.failureMessage || Translation.tr("Incorrect password")) : ""
    property bool ctrlHeld: false
    // the designs were drawn at 1280×720: s scales them to the screen (2 on a 2560×1440 monitor)
    readonly property real s: Math.max(0.6, Math.min(width / 1280, height / 720))
    readonly property color colText: Appearance.colors.colOnLayer0      // text straight on the (blurred) wallpaper
    readonly property color colTextDim: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.3)

    function forceFieldFocus() {
        if (root.passwordField) root.passwordField.focusField();
    }
    function tryUnlock() {
        if (root.preview) { root.context.clearText(); return; }
        root.context.tryUnlock(root.ctrlHeld, true);   // the arrow button: an empty password only on purpose
    }
    function sleep() {
        if (root.preview) return;
        Session.suspend();
    }
    // Shut down / restart: straight away, or after the password when lock.security.requirePasswordToPower is on
    function power(action) {
        if (root.preview) return;
        if (!root.requirePasswordToPower) {
            root.context.unlocked(action);
            return;
        }
        if (root.context.targetAction === action) {
            root.context.resetTargetAction();
        } else {
            root.context.targetAction = action;
            root.context.shouldReFocus();
        }
    }
    readonly property var actionPoweroff: LockContext.ActionEnum.Poweroff
    readonly property var actionReboot: LockContext.ActionEnum.Reboot

    Connections {
        target: root.context
        function onShouldReFocus() { root.forceFieldFocus(); }
    }
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onPressed: root.forceFieldFocus()
    onPositionChanged: root.forceFieldFocus()
    Component.onCompleted: root.forceFieldFocus()

    Keys.onPressed: event => {
        root.context.resetClearTimer();
        if (event.key === Qt.Key_Control) root.ctrlHeld = true;
        if (event.key === Qt.Key_Escape) root.context.currentText = "";
        root.forceFieldFocus();
    }
    Keys.onReleased: event => {
        if (event.key === Qt.Key_Control) root.ctrlHeld = false;
        root.forceFieldFocus();
    }
}
