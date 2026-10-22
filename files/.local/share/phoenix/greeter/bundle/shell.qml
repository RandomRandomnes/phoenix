//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
// Phoenix login screen (2026-10-08; 2026-10-22: in the lock screen's look). Runs under greetd as the "greeter" user
// inside the cage compositor:   cage -s -m last -- qs -p /usr/share/phoenix-greeter/shell.qml
// (set up by `phoenix login-screen install`, which builds this folder: these files + copies of the desktop shell's lock
// screen styles and the widgets they use, see phoenix-greeter-build).
// Look: what the last user's desktop copied to /var/lib/phoenix-greeter/theme at sign-in (phoenix-greeter-theme):
// colors.json, the wallpaper, account pictures, clock.json and lock-config.json (which lock style, fonts, blur).
// The style chosen in Settings › Personalization › Lock screen is shown; "Original" (illogical-impulse's own lock
// screen, which needs the whole desktop) and any style that fails to load fall back to the classic login screen.
// Remembers the last user and session in /var/lib/phoenix-greeter/state/last.json (owned by the greeter user).
// An empty password is never sent by Enter (each attempt counts towards the account lockout).
// PHOENIX_GREETER_THEME / _STATE / _STYLE / _PREVIEW=1: only for a preview outside greetd (nothing signs in, no power).
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import qs
import qs.services
import qs.modules.common
import qs.modules.common.panels.lock
import "modules/greeter"
import "modules/ii/lock/styles" as Styles

ShellRoot {
    id: root

    readonly property string themeDir: Config.themeDir
    readonly property string stateFile: Quickshell.env("PHOENIX_GREETER_STATE") || "/var/lib/phoenix-greeter/state/last.json"
    readonly property bool preview: Quickshell.env("PHOENIX_GREETER_PREVIEW") === "1"
    readonly property string style: Quickshell.env("PHOENIX_GREETER_STYLE") || (Config.options.lock.style ?? "original")
    // loaded as types (a Loader given the file's address can't see the style's neighbours, e.g. LockStyleBase)
    readonly property var styleComponents: ({
        "islands": islandsStyle, "cookie": cookieStyle, "frosted": frostedStyle, "hello": helloStyle,
        "editorial": editorialStyle, "clock": clockStyle, "user": userStyle, "bar": barStyle, "plain": plainStyle,
    })
    Component { id: islandsStyle; Styles.LockStyleIslands { context: lockContext } }
    Component { id: cookieStyle; Styles.LockStyleCookie { context: lockContext } }
    Component { id: frostedStyle; Styles.LockStyleFrosted { context: lockContext } }
    Component { id: helloStyle; Styles.LockStyleHello { context: lockContext } }
    Component { id: editorialStyle; Styles.LockStyleEditorial { context: lockContext } }
    Component { id: clockStyle; Styles.LockStyleClock { context: lockContext } }
    Component { id: userStyle; Styles.LockStyleUser { context: lockContext } }
    Component { id: barStyle; Styles.LockStyleBar { context: lockContext } }
    Component { id: plainStyle; Styles.LockStylePlain { context: lockContext } }
    property bool styleFailed: false
    readonly property bool styled: !root.styleFailed && root.styleComponents[root.style] !== undefined

    // colors of the classic login screen (the styles use Appearance, filled from the same colors.json)
    property var colors: ({})
    function col(name, fallback) { return root.colors[name] || fallback }
    readonly property color cBg: col("surface", "#141218")
    readonly property color cCard: col("surface_container", "#211f26")
    readonly property color cText: col("on_surface", "#e6e0e9")
    readonly property color cSub: col("on_surface_variant", "#cac4d0")
    readonly property color cPrimary: col("primary", "#d0bcff")
    readonly property color cOnPrimary: col("on_primary", "#381e72")
    readonly property color cOnWall: "#f4eff4"            // over the darkened wallpaper: always light text
    readonly property color cAccent: col("primary_fixed", "#eaddff")
    readonly property color cOnAccent: col("on_primary_fixed", "#21005d")
    readonly property string fontMain: "Google Sans Flex"
    readonly property string fontIcons: "Material Symbols Rounded"

    property var users: []            // [{name, real}] from /etc/passwd: uid 1000-59999 with a login shell
    property int userIndex: 0
    readonly property var user: users[userIndex] ?? null
    property var sessions: [{ id: "hyprland", name: "Phoenix (Hyprland)" }]
    property int sessionIndex: 0
    property string message: ""
    property bool messageIsError: false
    property bool busy: false
    property string pendingPassword: ""
    property var last: ({})
    property string nextSession: ""
    property string clockFormat: "hh:mm"

    // the styles show the picked account's name and picture
    Binding { target: SystemInfo; property: "username"; value: root.user ? (root.user.real || root.user.name) : "" }
    Binding { target: Config; property: "user"; value: root.user?.name ?? "" }

    // ── data ──
    FileView {
        path: root.themeDir + "/colors.json"
        printErrors: false
        onLoaded: {
            try { root.colors = JSON.parse(text()) } catch (e) { return }
            // the same mapping as the desktop's MaterialThemeLoader: snake_case → Appearance.m3colors.m3CamelCase
            for (const key in root.colors)
                Appearance.m3colors["m3" + key.replace(/_([a-z])/g, g => g[1].toUpperCase())] = root.colors[key]
            Appearance.m3colors.darkmode = Appearance.m3colors.m3background.hslLightness < 0.5
        }
    }
    FileView {
        path: "/etc/passwd"
        onLoaded: {
            const list = []
            for (const line of text().split("\n")) {
                const f = line.split(":")
                const uid = Number(f[2])
                if (f.length >= 7 && uid >= 1000 && uid < 60000 && !/(nologin|false)$/.test(f[6]))
                    list.push({ name: f[0], real: (f[4] || "").split(",")[0] })
            }
            root.users = list
            root.pickLast()
        }
    }
    FileView {   // switch-desktop's choice for the next sign-in (Settings › "Switch to KDE"), else the last one used
        path: root.themeDir + "/next-session"
        printErrors: false
        onLoaded: { root.nextSession = text().trim(); root.pickLast() }
    }
    FileView {
        path: root.themeDir + "/clock.json"
        printErrors: false
        onLoaded: { try { root.clockFormat = JSON.parse(text()).format || "hh:mm" } catch (e) {} }
    }
    FileView {
        id: stateView
        path: root.stateFile
        printErrors: false
        onLoaded: { try { root.last = JSON.parse(text()) } catch (e) {} root.pickLast() }
    }
    Process {   // KDE Plasma is offered only where it's installed
        running: true
        command: ["test", "-x", "/usr/bin/startplasma-wayland"]
        onExited: code => {
            if (code === 0) root.sessions = root.sessions.concat([{ id: "plasma", name: "KDE Plasma" }])
            root.pickLast()
        }
    }
    function pickLast() {
        const ui = root.users.findIndex(u => u.name === root.last.user)
        if (ui >= 0) root.userIndex = ui
        const si = root.sessions.findIndex(s => s.id === (root.nextSession || root.last.session))
        if (si >= 0) root.sessionIndex = si
    }
    function pickUser(index) {
        root.userIndex = index
        root.message = ""
        GlobalStates.screenUnlockFailed = false
        lockContext.clearText()
        lockContext.shouldReFocus()
    }

    // ── signing in ──
    function signIn(password) {
        if (!root.user || root.busy) return
        root.busy = true
        root.message = ""
        if (root.preview) {   // nothing can sign in here
            root.busy = false
            root.message = "Preview: nobody is signed in"
            lockContext.clearText()
            return
        }
        root.pendingPassword = password
        Greetd.createSession(root.user.name)
    }
    function power(cmd) {
        if (root.preview) console.log("preview: " + cmd + " (not done)")
        else Quickshell.execDetached(["systemctl", cmd])
    }
    function failed(text) {
        root.message = text
        root.messageIsError = true
        lockContext.failureMessage = text
        GlobalStates.screenUnlockFailed = true
        lockContext.clearText()
        lockContext.failed()
        lockContext.shouldReFocus()
    }

    LockContext {
        id: lockContext
        unlockInProgress: root.busy
        onSignInRequested: password => root.signIn(password)
        onUnlocked: action => {
            if (action === LockContext.ActionEnum.Poweroff) root.power("poweroff")
            else if (action === LockContext.ActionEnum.Reboot) root.power("reboot")
        }
        // a new try clears the last error, like the lock screen
        onCurrentTextChanged: if (currentText.length > 0) GlobalStates.screenUnlockFailed = false
    }

    Connections {
        target: Greetd
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) {
                Greetd.respond(root.pendingPassword)
                root.pendingPassword = ""
            } else if (message) {
                root.message = message
                root.messageIsError = error
            }
        }
        function onReadyToLaunch() {
            const s = root.sessions[root.sessionIndex]
            stateView.setText(JSON.stringify({ user: root.user.name, session: s.id }))
            root.message = "Signing in…"
            root.messageIsError = false
            Greetd.launch(["/usr/local/bin/phoenix-session", s.id], ["XDG_SESSION_TYPE=wayland", "PHOENIX_AUTHENTICATED=1"], true)   // signed in: no lock-first start (phoenix-session)
        }
        function onAuthFailure(message) {
            justFailed.restart()
            root.busy = false
            root.pendingPassword = ""
            // faillock answers every attempt while the account is locked; its notice came as an info message (any
            // notice counts: it is in the system's language; L22). Minutes: the number before "minute", else the last one.
            const info = root.message.trim()
            const locked = info !== ""
            const nums = info.match(/\d+/g) || []
            const mins = (info.match(/(\d+)\s*minute/i) || [])[1] ?? nums[nums.length - 1]
            root.failed(locked ? `Too many attempts. Try again in ${mins ? mins + " minute" + (mins === "1" ? "" : "s") : "a few minutes"}.`
                               : "That password isn't right. Try again.")
        }
        function onError(error) {
            // after a wrong password Quickshell cancels the session greetd already closed; that "error" isn't one
            if (justFailed.running) return
            root.busy = false
            root.pendingPassword = ""
            root.failed("Couldn't sign in: " + error)
            Greetd.cancelSession()
        }
    }

    Timer { id: justFailed; interval: 2000 }

    // ── screen ──
    FloatingWindow {
        id: win
        visible: true
        color: root.styled ? Appearance.colors.colLayer0 : root.cBg

        // the wallpaper like the lock screen shows it: blurred (Settings › Lock screen › blur), a little zoomed in
        Image {
            id: wallpaper
            anchors.fill: parent
            source: "file://" + root.themeDir + "/wallpaper"
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: win.width   // no need to keep a 4K picture in memory for a blurred background
            scale: root.styled && (Config.options.lock.blur?.enable ?? true) ? (Config.options.lock.blur?.extraZoom ?? 1.1) : 1
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: !root.styled || (Config.options.lock.blur?.enable ?? true)
                blur: root.styled ? Math.min(1, (Config.options.lock.blur?.radius ?? 100) / 100) : 0.8
                blurMax: 64
                brightness: root.styled ? -0.1 : -0.25
            }
        }

        Loader {   // the lock screen style
            id: styleLoader
            anchors.fill: parent
            focus: true
            active: Config.ready && root.styled
            sourceComponent: root.styleComponents[root.style] ?? null
            onStatusChanged: if (status === Loader.Error) {
                console.warn(`[greeter] style "${root.style}" couldn't be loaded; using the classic login screen`)
                root.styleFailed = true
            }
        }

        Loader {   // the classic login screen ("Original", or when a style fails)
            anchors.fill: parent
            active: Config.ready && !root.styled
            sourceComponent: ClassicView { greeter: root; context: lockContext }
        }

        GreeterChips {   // on a style: other accounts and the desktop to start, top right
            visible: Config.ready && root.styled
            greeter: root
            anchors { top: parent.top; right: parent.right; margins: 24 }
        }

        Rectangle {   // on a style: "Signing in…" and the lockout notice the style has no room for
            visible: root.styled && root.message !== "" && !root.messageIsError
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 24 }
            radius: height / 2
            implicitHeight: 40
            implicitWidth: msg.implicitWidth + 40
            color: Appearance.colors.colLayer2
            Text {
                id: msg
                anchors.centerIn: parent
                text: root.message
                font { family: Appearance.font.family.main; pixelSize: 15 }
                color: Appearance.colors.colOnLayer2
            }
        }
    }
}
