#!/usr/bin/env python3
"""What really starts when you sign in, for Settings › Apps › Startup and the Task Manager (Phoenix, 2026-10-16).

Prints JSON: {"script": {"path", "exists", "programs": [names]},
              "plasma": [{"id", "name", "exec", "icon", "covered": "script"|"phoenix"|""}],
              "installed": {"steam", "wallpaperEngine", "phoneLink": bool}}
script = your own startup script (~/.config/hypr/custom/scripts/autostart-user.sh), the programs it runs.
plasma = ~/.config/autostart entries: KDE Plasma starts these, Phoenix (Hyprland) does not. "covered" tells when
Phoenix already does the same thing another way (your script mounts that drive; Phoenix starts Wallpaper Engine).
Phoenix's own startup (Steam in the tray, Wallpaper Engine, Phone Link) and the Settings startup list come from the
shell's settings, not from here.
"""
import configparser
import json
import os
import re
import shlex
import shutil

HOME = os.path.expanduser("~")
SCRIPT = os.path.join(HOME, ".config/hypr/custom/scripts/autostart-user.sh")
XDG_AUTOSTART = os.path.join(os.environ.get("XDG_CONFIG_HOME") or os.path.join(HOME, ".config"), "autostart")
SHELL_WORDS = {"for", "do", "done", "if", "then", "else", "elif", "fi", "while", "until", "case", "esac", "in", "[", "[[",
               "test", "sleep", "echo", "printf", "true", "false", "export", "local", "cd", "exit", "return", "seq",
               "findmnt", "grep", "read", "set", "wait", "mkdir", "touch", "command", "exec", "nohup", "setsid", "env",
               "sh", "bash", "pgrep", "pidof", "break", "continue", "shift", "source", ".", "trap", "unset", "let"}


def script_programs(text):
    progs = []
    for line in text.splitlines():
        line = line.split("#", 1)[0].strip()
        if not line:
            continue
        try:
            toks = shlex.split(line.replace("$(", " ").replace(")", " "), posix=True)
        except ValueError:
            toks = line.split()
        start = True
        for t in toks:
            if t in (";", "&&", "||", "|", "&", "do", "then", "else"):
                start = True
                continue
            if start:
                start = False
                if "=" in t.split("/")[0] and not t.startswith(("/", "$", "~")):
                    start = True      # VAR=value: the command follows
                    continue
                name = os.path.basename(t.replace("$HOME", HOME))
                name = re.sub(r"[;&|]+$", "", name)
                if name and name not in SHELL_WORDS and not name.startswith("$") and name not in progs:
                    progs.append(name)
            if t.endswith((";", "&")):
                start = True
    return progs


def plasma_entries(script_text):
    out = []
    if not os.path.isdir(XDG_AUTOSTART):
        return out
    for f in sorted(os.listdir(XDG_AUTOSTART)):
        if not f.endswith(".desktop"):
            continue
        cfg = configparser.ConfigParser(interpolation=None, strict=False)
        cfg.optionxform = str
        try:
            cfg.read(os.path.join(XDG_AUTOSTART, f))
            e = cfg["Desktop Entry"]
        except (configparser.Error, KeyError, UnicodeDecodeError):
            continue
        if e.get("Hidden", "false") == "true" or e.get("X-GNOME-Autostart-enabled", "true") == "false":
            continue
        only = [x for x in e.get("OnlyShowIn", "").split(";") if x]
        if only and "KDE" not in only:
            continue
        exe = re.sub(r"\s%[fFuUdDnNickvm]", "", e.get("Exec", "")).strip()
        covered = ""
        first = os.path.basename(shlex.split(exe)[0]) if exe else ""
        # the same drive or command already in your startup script
        uuids = re.findall(r"[0-9A-Fa-f-]{16,36}", exe)
        if (uuids and any(u in script_text for u in uuids)) or (first and first not in SHELL_WORDS and re.search(rf"\b{re.escape(first)}\b", script_text)):
            covered = "script"
        elif first.startswith("linux-wallpaper-engine"):
            covered = "phoenix"
        out.append({"id": f[:-8], "name": e.get("Name", f[:-8]), "exec": exe, "icon": e.get("Icon", ""), "covered": covered})
    return out


def main():
    text = ""
    if os.path.isfile(SCRIPT):
        with open(SCRIPT, errors="ignore") as fh:
            text = fh.read()
    # which of Phoenix's own startup programs are installed (the Task Manager only lists those)
    have = {"steam": shutil.which("steam") is not None,
            "wallpaperEngine": shutil.which("linux-wallpaper-engine-ux") is not None,
            "phoneLink": shutil.which("kdeconnectd") is not None or os.path.exists("/usr/bin/kdeconnectd")}
    print(json.dumps({"script": {"path": SCRIPT, "exists": os.path.isfile(SCRIPT), "programs": script_programs(text)},
                      "plasma": plasma_entries(text), "installed": have}))


if __name__ == "__main__":
    main()
