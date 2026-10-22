pragma Singleton
import QtQuick
import Quickshell

// Phoenix login screen (2026-10-22): the one GlobalStates value the lock screen styles read
Singleton {
    property bool screenUnlockFailed: false
}
