pragma Singleton
import QtQuick
import Quickshell

// Phoenix login screen (2026-10-22): no home folder here (the account picture comes through Config.options.profile)
Singleton {
    readonly property string home: "/nonexistent"
}
