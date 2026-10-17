#!/usr/bin/env python3
"""Change your own password without a terminal (Settings › Accounts, Phoenix 2026-10-16).

Reads two lines on stdin: the current password, then the new one. Runs `passwd` in a pseudo-terminal (it only talks
to a terminal) and answers its three questions. Prints one JSON line: {"ok": bool, "message": "..."} with passwd's
own explanation when it refuses (wrong current password, too short, too simple…). Nothing is stored or logged.
"""
import json
import os
import pty
import re
import select
import sys
import time


def main():
    lines = sys.stdin.read().split("\n")
    current = lines[0] if lines else ""
    new = lines[1] if len(lines) > 1 else ""
    if not new:
        print(json.dumps({"ok": False, "message": "Type a new password."}))
        return 1
    pid, fd = pty.fork()
    if pid == 0:
        os.environ["LC_ALL"] = "C"   # English prompts to answer; the messages are translated below
        os.execvp("passwd", ["passwd"])
    out = b""
    answered = {"current": False, "new": False, "retype": False}
    deadline = time.time() + 30
    while time.time() < deadline:
        r, _, _ = select.select([fd], [], [], 0.5)
        if not r:
            continue
        try:
            chunk = os.read(fd, 1024)
        except OSError:
            break
        if not chunk:
            break
        out += chunk
        text = out.decode(errors="ignore").lower()
        tail = text[-200:]
        if not answered["current"] and re.search(r"current.*password:\s*$", tail):
            os.write(fd, (current + "\n").encode()); answered["current"] = True
        elif not answered["new"] and re.search(r"new password:\s*$", tail) and "retype" not in tail[-40:]:
            os.write(fd, (new + "\n").encode()); answered["new"] = True
        elif answered["new"] and not answered["retype"] and re.search(r"(retype|re-enter).*password:\s*$", tail):
            os.write(fd, (new + "\n").encode()); answered["retype"] = True
        elif answered["new"] and not answered["retype"] and re.search(r"new password:\s*$", tail):
            break   # asked for a new password again: the first one was refused (message above)
    try:
        os.kill(pid, 15)
    except OSError:
        pass
    _, status = os.waitpid(pid, 0)
    text = out.decode(errors="ignore")
    ok = os.WIFEXITED(status) and os.WEXITSTATUS(status) == 0 and "successfully" in text.lower()
    if ok:
        msg = "Your password was changed."
    else:
        low = text.lower()
        if "authentication token manipulation error" in low or "authentication failure" in low:
            msg = "The current password isn't right."
        else:
            bad = re.findall(r"bad password: ?(.*)", text, re.I)
            msg = ("The new password was refused: " + bad[-1].strip()) if bad else "The password wasn't changed."
    print(json.dumps({"ok": ok, "message": msg}))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
