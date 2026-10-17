pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

// Background jobs run by the shell instead of in a terminal (Phoenix, 2026-10-16): updates, restore points, app
// installs, cleanup… Each job is a Process; admin rights come from sudo asking in the shell's own password dialog
// (SUDO_ASKPASS=~/.local/bin/phoenix-askpass, services/PolkitService.qml). Pages show `Tasks.jobs[id]` (progress,
// log, result) and react to `finished(id, ok)`.
// Jobs may print these lines (system-update --gui does): "@@step <name>" (current step), "@@msg <text>" (result
// line), "@@relogin" / "@@reboot" (a sign-out / restart completes it), "@@needmode", "@@stop <why>".
Singleton {
    id: root

    // id → { id, title, running, step, log: [lines], msgs: [lines], exitCode, ok, relogin, reboot, flags: [..] }
    property var jobs: ({})
    signal finished(string id, bool ok)

    function job(id) { return root.jobs[id] ?? null }
    function isRunning(id) { return root.jobs[id]?.running ?? false }
    function anyRunning() { return Object.values(root.jobs).some(j => j.running) }

    // start a job (ignored while one with the same id runs). opts: { title, notify (default true), doneText, failText,
    // askpassMessage }
    function run(id, command, opts) {
        if (root.isRunning(id)) return false;
        const o = opts ?? {};
        const j = { id: id, title: o.title ?? id, running: true, step: "", log: [], msgs: [], exitCode: -1, ok: false,
                    relogin: false, reboot: false, flags: [], notify: o.notify !== false,
                    doneText: o.doneText ?? "", failText: o.failText ?? "" };
        root.set(id, j);
        // SUDO_ASKPASS + a `sudo` that always uses it (scripts/askpass-bin/sudo, first on PATH)
        const env = { "SUDO_ASKPASS": `${Quickshell.env("HOME")}/.local/bin/phoenix-askpass`,
                      "PATH": `${Quickshell.shellPath("scripts/askpass-bin")}:${Quickshell.env("PATH")}` };
        if (o.askpassMessage) env["PHOENIX_ASKPASS_MESSAGE"] = o.askpassMessage;
        // setsid: no controlling terminal. On a console sign-in (tty1) the shell has one, and sudo would ask on that
        // invisible terminal instead of the password dialog (found in the VM test, 2026-10-16)
        const p = jobComp.createObject(root, { jobId: id, command: ["setsid", "-w"].concat(command), environment: env });
        p.running = true;
        return true;
    }
    function clear(id) {
        if (root.isRunning(id)) return;
        const m = Object.assign({}, root.jobs);
        delete m[id];
        root.jobs = m;
    }

    function set(id, j) {
        const m = Object.assign({}, root.jobs);
        m[id] = j;
        root.jobs = m;
    }
    function update(id, fn) {
        const cur = root.jobs[id];
        if (!cur) return;
        const j = Object.assign({}, cur);
        fn(j);
        root.set(id, j);
    }
    function addLine(id, raw) {
        // a read can hold several lines (an empty line arrived glued to the next one): handle each
        const parts = String(raw).split("\n");
        if (parts.length > 1) { parts.forEach(p => root.addLine(id, p)); return; }
        // carriage-return progress bars: keep the last state of the line; then drop terminal escape sequences (colours,
        // charset switches like ESC ( B) and other control characters, which can sit in front of a marker
        const line = raw.split("\r").pop()
            .replace(/\x1b(\[[0-9;?]*[ -\/]*[@-~]|\][^\x07]*\x07|[()][A-Za-z0-9]|[@-Z\\-_])/g, "")
            .replace(/[\x00-\x08\x0b-\x1f\x7f]/g, "");
        const m = line.match(/@@(step|msg) (.*)$/) || line.match(/@@(relogin|reboot|needmode|stop)\b ?(.*)$/);
        root.update(id, j => {
            if (m && m[1] === "step") j.step = m[2];
            else if (m && m[1] === "msg") j.msgs = j.msgs.concat([m[2]]);
            else if (m && m[1] === "relogin") j.relogin = true;
            else if (m && m[1] === "reboot") j.reboot = true;
            else if (m) j.flags = j.flags.concat([m[1] + (m[2] ? " " + m[2] : "")]);
            else if (line.trim() !== "") j.log = j.log.concat([line]).slice(-300);
        });
    }

    Component {
        id: jobComp
        Process {
            id: proc
            property string jobId
            stdout: SplitParser { onRead: line => root.addLine(proc.jobId, line) }
            stderr: SplitParser { onRead: line => root.addLine(proc.jobId, line) }
            onExited: (code, status) => {
                let done = null;
                root.update(proc.jobId, j => { j.running = false; j.exitCode = code; j.ok = code === 0; done = j; });
                if (done && done.notify && !done.flags.includes("needmode")) {
                    const body = done.msgs.length > 0 ? done.msgs.join("\n") : (done.ok ? done.doneText : done.failText);
                    Quickshell.execDetached(["notify-send", "-a", "Phoenix", ...(done.ok ? [] : ["-u", "critical"]),
                        done.ok ? `${done.title}: done` : `${done.title}: needs attention`, body || (done.ok ? "Finished." : "See Settings for details.")]);
                }
                root.finished(proc.jobId, code === 0);
                proc.destroy();
            }
        }
    }
}
