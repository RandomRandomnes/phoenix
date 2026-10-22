pragma Singleton
import QtQuick
import Quickshell

// Phoenix login screen (2026-10-22): no translations here (the login screen's own texts are English too)
Singleton {
    function tr(text) { return text ? text.toString() : ""; }
}
