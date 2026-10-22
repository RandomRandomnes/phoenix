pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Phoenix login screen (2026-10-22): stands in for the desktop's settings. The signed-in desktop copies its look
// (stock defaults + its own appearance / lock / time settings) to lock-config.json in the theme folder at each sign-in
// (phoenix-greeter-theme); the built-in values below are only used until that file exists.
Singleton {
    id: root
    readonly property string themeDir: Quickshell.env("PHOENIX_GREETER_THEME") || "/var/lib/phoenix-greeter/theme"
    property string user: ""            // the account picked on the login screen (its picture)
    property bool ready: false          // lock-config.json read (or missing): until then nothing is shown, so the
                                        // classic look doesn't flash before the chosen style
    property var loaded: ({})
    readonly property var defaults: ({
        appearance: {
            extraBackgroundTint: true,
            fonts: { expressive: "Space Grotesk", iconNerd: "JetBrains Mono NF", main: "Google Sans Flex", monospace: "JetBrains Mono NF",
                     numbers: "Google Sans Flex", reading: "Readex Pro", title: "Google Sans Flex" },
            transparency: { automatic: true, backgroundTransparency: 0.11, contentTransparency: 0.57, enable: false }
        },
        background: { wallpaperPath: "", thumbnailPath: "" },
        bar: { cornerStyle: 0 },
        hacks: { arbitraryRaceConditionDelay: 100 },
        time: { format: "hh:mm", dateFormat: "ddd, dd/MM", shortDateFormat: "dd/MM", dateWithYearFormat: "dd/MM/yyyy" },
        lock: { style: "original", blur: { enable: true, extraZoom: 1.1, radius: 100 }, showLockedText: true, showMedia: true,
                showToolbars: true, materialShapeChars: true, centerClock: true }
    })
    FileView {
        path: root.themeDir + "/lock-config.json"
        blockLoading: true
        printErrors: false
        onLoaded: { try { root.loaded = JSON.parse(text()) } catch (e) {} root.ready = true }
        onLoadFailed: root.ready = true
    }
    function merged(a, b) {   // b over a, object by object
        const o = Object.assign({}, a)
        for (const k in b) {
            const v = b[k]
            o[k] = (v && typeof v === "object" && !Array.isArray(v) && a[k] && typeof a[k] === "object") ? merged(a[k], v) : v
        }
        return o
    }
    readonly property var options: {
        const o = merged(root.defaults, root.loaded)
        // at the login screen the power buttons always work without a password, and nothing is "Locked" (nobody is
        // signed in yet)
        o.lock = merged(o.lock, { security: { requirePasswordToPower: false }, showLockedText: false, atLogin: true })
        o.profile = { avatarPath: "greeter", avatarPicture: root.user ? root.themeDir + "/face-" + root.user : "" }
        return o
    }
}
