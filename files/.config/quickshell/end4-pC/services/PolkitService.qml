pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Polkit

// The shell's password dialog (modules/ii/polkit). Two sources (Phoenix, 2026-10-16):
//  - polkit requests (pkexec, apps asking for admin rights): Quickshell's PolkitAgent
//  - sudo through ~/.local/bin/phoenix-askpass (SUDO_ASKPASS): updates and other admin jobs run by the shell use sudo
//    (yay needs it); the helper asks over IPC ("askpass ask <fifo> <message>") and reads the answer from a fifo in
//    $XDG_RUNTIME_DIR that only this user can open. So every password prompt looks the same and no terminal is needed.
Singleton {
    id: root
    property alias agent: polkitAgent
    property alias flow: polkitAgent.flow
    property bool interactionAvailable: false

    // a pending sudo password request: { fifo, message }
    property var askpass: null
    readonly property bool active: polkitAgent.isActive || root.askpass !== null

    property string cleanMessage: {
        if (root.askpass) return root.askpass.message;
        if (!root.flow) return "";
        return root.flow.message.endsWith(".")
            ? root.flow.message.slice(0, -1)
            : root.flow.message
    }
    readonly property bool usePasswordChars: root.askpass ? true : (!root.flow?.responseVisible ?? true)
    property string cleanPrompt: {
        if (root.askpass) return Translation.tr("Password");
        const inputPrompt = root.flow?.inputPrompt.trim() ?? "";
        const cleanedInputPrompt = inputPrompt.endsWith(":") ? inputPrompt.slice(0, -1) : inputPrompt;
        return cleanedInputPrompt || (root.usePasswordChars ? Translation.tr("Password") : Translation.tr("Input"))
    }

    function cancel() {
        if (root.askpass) { root.answerAskpass(""); return; }
        root.flow.cancelAuthenticationRequest()
    }

    function submit(string) {
        if (root.askpass) { root.answerAskpass(string); return; }
        root.flow.submit(string)
        root.interactionAvailable = false
    }

    // hand the answer to phoenix-askpass (an empty line = cancelled) and close the dialog
    function answerAskpass(text) {
        const req = root.askpass;
        root.askpass = null;
        root.interactionAvailable = false;
        if (!req) return;
        const writer = askpassWriter.createObject(root, { fifo: req.fifo });
        writer.answer = text;
        writer.running = true;
    }
    Component {
        id: askpassWriter
        Process {
            id: w
            property string fifo
            property string answer
            command: ["sh", "-c", "cat > \"$1\"", "_", w.fifo]
            stdinEnabled: true
            onStarted: { w.write(w.answer + "\n"); w.answer = ""; w.stdinEnabled = false; }
            onExited: w.destroy()
        }
    }
    IpcHandler {
        target: "askpass"
        function ask(fifo: string, message: string): void {
            if (root.askpass) root.answerAskpass("");     // an older request still open: cancel it
            root.askpass = { fifo: fifo, message: message || Translation.tr("Enter your password to continue") };
            root.interactionAvailable = true;
        }
    }

    Connections {
        target: root.flow
        function onAuthenticationFailed() {
            root.interactionAvailable = true;
        }
    }

    PolkitAgent {
        id: polkitAgent
        onAuthenticationRequestStarted: {
            root.interactionAvailable = true;
        }
    }
}
