pragma Singleton
import QtQuick
import Quickshell

// Phoenix login screen (2026-10-22): the one Session action the styles use
Singleton {
    readonly property bool preview: Quickshell.env("PHOENIX_GREETER_PREVIEW") === "1"
    function suspend() {
        if (preview) console.log("preview: suspend (not done)");
        else Quickshell.execDetached(["systemctl", "suspend"]);
    }
}
