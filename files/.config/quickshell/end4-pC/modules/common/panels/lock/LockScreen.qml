pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    required property Component lockSurface
    property alias context: lockContext
    property Component sessionLockSurface: WlSessionLockSurface {
        id: sessionLockSurface
        color: "transparent"
        Loader {
            active: GlobalStates.screenLocked
            anchors.fill: parent
            opacity: active ? 1 : 0
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
            sourceComponent: root.lockSurface
        }
    }

    Process {
        id: unlockKeyringProc
        onExited: (exitCode, exitStatus) => {
            KeyringStorage.fetchKeyringData();
        }
    }
    function unlockKeyring() {
        unlockKeyringProc.exec({
            environment: ({
                "UNLOCK_PASSWORD": lockContext.currentText
            }),
            command: ["bash", "-c", Quickshell.shellPath("scripts/keyring/unlock.sh")]
        })
    }

    // This stores all the information shared between the lock surfaces on each screen.
    // https://github.com/quickshell-mirror/quickshell-examples/tree/master/lockscreen
    LockContext {
        id: lockContext

        Connections {
            target: GlobalStates
            function onScreenLockedChanged() {
                if (GlobalStates.screenLocked) {
                    lockContext.reset();
                    lockContext.tryFingerUnlock();
                }
            }
        }

        onUnlocked: (targetAction) => {
            // Perform the target action if it's not just unlocking
            if (targetAction == LockContext.ActionEnum.Poweroff) {
                Session.poweroff();
                return;
            } else if (targetAction == LockContext.ActionEnum.Reboot) {
                Session.reboot();
                return;
            }

            // Unlock the keyring if configured to do so
            if (Config.options.lock.security.unlockKeyring) root.unlockKeyring(); // Async

            // Unlock the screen before exiting, or the compositor will display a
            // fallback lock you can't interact with.
            GlobalStates.screenLocked = false;

            // Reset
            lockContext.reset();

            // Post-unlock actions
            if (lockContext.alsoInhibitIdle) {
                lockContext.alsoInhibitIdle = false;
                Idle.toggleInhibit(true);
            }
        }
    }

    WlSessionLock {
        id: lock
        locked: GlobalStates.screenLocked
        surface: root.sessionLockSurface
        onSecureChanged: {
            if (lock.secure) GlobalStates.startupLockPending = false;
            if (lock.secure && GlobalStates.lockFirst && !GlobalStates.startupGateOpen) root.startupLockIsUp();
        }
    }

    // ---- Phoenix lock-screen sign-in (2026-10-15) -------------------------------------------------------------------
    // phoenix-session starts the desktop without a password (greetd autologin) and sets PHOENIX_LOCK_FIRST=1. Then the
    // lock comes first, whatever the lock.launchOnStartup setting says, and the rest of the shell waits for it.
    // "Unlocked once" lives in $XDG_RUNTIME_DIR (gone at reboot/logout): a shell restarted before the first unlock locks
    // again instead of leaving Hyprland's red "lock screen died" screen.
    readonly property string runDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    property bool unlockedOnce: false
    property bool unlockedOnceKnown: !GlobalStates.lockFirst
    property bool initDone: false
    FileView {
        path: GlobalStates.lockFirst ? `${root.runDir}/phoenix-unlocked-once` : ""
        printErrors: false
        onLoaded: { root.unlockedOnce = true; root.unlockedOnceKnown = true; root.initIfReady(); }
        onLoadFailed: { root.unlockedOnceKnown = true; root.initIfReady(); }
    }
    Timer {
        id: gateTimer
        interval: 1000          // a moment of margin after the compositor confirmed the lock
        onTriggered: GlobalStates.startupGateOpen = true
    }
    function startupLockIsUp() {
        // tell phoenix-session's watchdog, and give the keyboard back (Hyprland started in an empty submap)
        Quickshell.execDetached(["sh", "-c", `touch "${root.runDir}/phoenix-lock-up"; hyprctl dispatch 'hl.dsp.submap("reset")' >/dev/null`]);
        gateTimer.restart();
    }
    Connections {
        target: GlobalStates
        enabled: GlobalStates.lockFirst
        function onScreenLockedChanged() {
            if (GlobalStates.screenLocked || root.unlockedOnce) return;
            // first unlock since the session started: the user's own startup items may run now (autostart.sh waits for this)
            root.unlockedOnce = true;
            GlobalStates.startupGateOpen = true;
            Quickshell.execDetached(["touch", `${root.runDir}/phoenix-unlocked-once`]);
        }
    }
    // -----------------------------------------------------------------------------------------------------------------

    function lock() {
        if (Config.options.lock.useHyprlock) {
            Quickshell.execDetached(["bash", "-c", "pidof hyprlock || hyprlock"]);
            return;
        }
        GlobalStates.screenLocked = true;
    }

    IpcHandler {
        target: "lock"

        function activate(): void {
            root.lock();
        }
        function focus(): void {
            lockContext.shouldReFocus();
        }
    }

    CompositorGlobalShortcut {
        name: "lock"
        description: "Locks the screen"

        onPressed: {
            root.lock()
        }
    }

    CompositorGlobalShortcut {
        name: "lockFocus"
        description: "Re-focuses the lock screen. This is because Hyprland after waking up for whatever reason"
            + "decides to keyboard-unfocus the lock screen"

        onPressed: {
            lockContext.shouldReFocus();
        }
    }

    function initIfReady() {
        if (!Config.ready || !Persistent.ready || !root.unlockedOnceKnown || root.initDone) return;
        root.initDone = true;
        if (GlobalStates.lockFirst) {
            if (!root.unlockedOnce) {
                GlobalStates.screenLocked = true;   // always the shell's own lock here (not hyprlock): the gate needs it
            } else {
                GlobalStates.startupGateOpen = true; // shell restarted after the first unlock: normal start
                KeyringStorage.fetchKeyringData();
                GlobalStates.startupLockPending = false;
            }
            return;
        }
        if (Config.options.lock.launchOnStartup && Persistent.isNewHyprlandInstance) {
            root.lock();
        } else {
            KeyringStorage.fetchKeyringData();
            GlobalStates.startupLockPending = false;
        }
    }
    Connections {
        target: Config
        function onReadyChanged() {
            root.initIfReady();
        }
    }
    Connections {
        target: Persistent
        function onReadyChanged() {
            root.initIfReady();
        }
    }
}