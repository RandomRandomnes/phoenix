pragma Singleton
import QtQuick
import Quickshell

// Phoenix login screen (2026-10-22): nothing plays before anyone signs in
Singleton {
    property var activePlayer: null
}
