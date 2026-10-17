#!/usr/bin/env python3
"""Keyboard shortcuts for Settings › Bluetooth & devices › Keyboard › Shortcuts and the Super+/ sheet (Phoenix P15,
2026-10-16, ours; not upstream).

  shortcuts.py list                         JSON: {"rows": [{category, what, keys, original, changed, off, added,
                                            command}], "errors": ""} — the shortcuts Hyprland has now (hyprctl binds),
                                            with your changes marked
  shortcuts.py set <original> <new> [--force]   put a shortcut on other keys; without --force a clash answers
                                            {"conflict": "<what uses them>"}; with it the other one is switched off
  shortcuts.py reset <original>             back to its default keys (also switches it on again)
  shortcuts.py off <keys> <what>            switch a shortcut off      shortcuts.py on <original>
  shortcuts.py add <keys> <command> <what>  your own command on keys   shortcuts.py remove <keys>

Your changes: ~/.config/hypr/custom/user-keybinds.json (this script's record) and user-keybinds.lua (what Hyprland
reads, see custom/env.lua). Both are personal: never shipped or replaced by updates. Hyprland is reloaded after a change;
the answer has its config errors, if any.
"""
import json
import os
import subprocess
import sys

HOME = os.path.expanduser("~")
DIR = os.path.join(HOME, ".config", "hypr", "custom")
JSON = os.path.join(DIR, "user-keybinds.json")
LUA = os.path.join(DIR, "user-keybinds.lua")
MODBITS = [(64, "SUPER"), (4, "CTRL"), (8, "ALT"), (1, "SHIFT")]
MODS = {"SUPER", "CTRL", "ALT", "SHIFT"}


def norm(keys):
    mods, key = [], ""
    for part in str(keys).split("+"):
        p = part.strip().upper()
        if p == "CONTROL":
            p = "CTRL"
        if p in MODS:
            mods.append(p)
        elif p:
            key = p
    return "+".join(sorted(mods) + ([key] if key else []))


def pretty(mods_mask, key):
    names = [n for bit, n in MODBITS if mods_mask & bit]
    return " + ".join(names + ([key] if key else []))


def load():
    try:
        with open(JSON) as f:
            d = json.load(f)
    except (OSError, ValueError):
        d = {}
    return {"moved": dict(d.get("moved") or {}), "off": dict(d.get("off") or {}), "added": list(d.get("added") or [])}


def lua_str(s):
    return '"' + str(s).replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ") + '"'


def save(d):
    os.makedirs(DIR, exist_ok=True)
    tmp = JSON + ".tmp"
    with open(tmp, "w") as f:
        json.dump(d, f, indent=2)
    os.replace(tmp, JSON)
    lines = ["-- Written by the shell's scripts/hyprland/shortcuts.py (Settings › Keyboard › Shortcuts). Read by",
             "-- custom/env.lua. Your own shortcut changes: never shipped or replaced by Phoenix updates.", "return {",
             "    moved = {"]
    lines += [f"        [{lua_str(k)}] = {lua_str(v)}," for k, v in d["moved"].items()]
    lines += ["    },", "    off = {"]
    lines += [f"        [{lua_str(k)}] = {lua_str(v or 'on')}," for k, v in d["off"].items()]
    lines += ["    },", "    added = {"]
    lines += [f"        {{ keys = {lua_str(a['keys'])}, command = {lua_str(a['command'])}, description = {lua_str(a.get('description') or a['command'])} }},"
              for a in d["added"]]
    lines += ["    },", "}", ""]
    tmp = LUA + ".tmp"
    with open(tmp, "w") as f:
        f.write("\n".join(lines))
    os.replace(tmp, LUA)


def reload():
    if not os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        return ""
    subprocess.run(["hyprctl", "reload"], capture_output=True)
    out = subprocess.run(["hyprctl", "configerrors"], capture_output=True, text=True).stdout.strip()
    return "" if out.lower() in ("", "no errors") else out[:600]


def binds():
    try:
        return json.loads(subprocess.run(["hyprctl", "binds", "-j"], capture_output=True, text=True).stdout or "[]")
    except ValueError:
        return []


def rows():
    d = load()
    moved_back = {norm(v): k for k, v in d["moved"].items()}   # current keys → original keys
    added = {norm(a["keys"]): a for a in d["added"]}
    out, seen = [], set()
    for b in binds():
        desc = b.get("description") or ""
        if not desc or b.get("submap"):
            continue
        keys = pretty(b.get("modmask", 0), b.get("key", ""))
        cat, _, what = desc.partition(": ") if ": " in desc else ("Other", "", desc)
        n = norm(keys)
        if (n, desc) in seen:
            continue
        seen.add((n, desc))
        original = moved_back.get(n, keys)
        out.append({"category": cat.strip(), "what": what.strip(), "keys": keys, "original": original,
                    "changed": norm(original) != n, "off": False, "added": n in added and cat.strip() == "Yours",
                    "command": added[n]["command"] if n in added and cat.strip() == "Yours" else ""})
    for k, what in d["off"].items():
        cat, _, w = str(what).partition(": ") if ": " in str(what) else ("Other", "", str(what))
        out.append({"category": cat.strip(), "what": w.strip(), "keys": k, "original": k, "changed": True, "off": True,
                    "added": False, "command": ""})
    order = ["App", "Window", "Workspace", "Shell", "Utilities", "Media", "Screen", "Session", "Yours", "Other"]
    out.sort(key=lambda r: (order.index(r["category"]) if r["category"] in order else len(order), r["what"].lower()))
    return out


def main():
    a = sys.argv[1:]
    cmd = a[0] if a else "list"
    if cmd == "list":
        print(json.dumps({"rows": rows()}))
        return 0
    d = load()
    if cmd == "set" and len(a) >= 3:
        original, new = a[1], a[2]
        n = norm(new)
        clash = [r for r in rows() if not r["off"] and norm(r["keys"]) == n and norm(r["original"]) != norm(original)]
        if clash and "--force" not in a:
            print(json.dumps({"conflict": clash[0]["what"], "category": clash[0]["category"]}))
            return 2
        for r in clash:   # "use anyway": the other shortcut is switched off (Settings can give it new keys later)
            if r["added"]:
                d["added"] = [x for x in d["added"] if norm(x["keys"]) != n]
            else:
                d["off"][r["original"]] = f"{r['category']}: {r['what']}"
                d["moved"].pop(r["original"], None)
        if norm(original) == n:
            d["moved"].pop(original, None)
        else:
            d["moved"][original] = new
    elif cmd == "reset" and len(a) >= 2:
        d["moved"].pop(a[1], None)
        d["off"].pop(a[1], None)
    elif cmd == "off" and len(a) >= 3:
        d["off"][a[1]] = a[2]
        d["moved"].pop(a[1], None)
    elif cmd == "on" and len(a) >= 2:
        d["off"].pop(a[1], None)
    elif cmd == "add" and len(a) >= 4:
        n = norm(a[1])
        clash = [r for r in rows() if not r["off"] and norm(r["keys"]) == n]
        if clash and "--force" not in a:
            print(json.dumps({"conflict": clash[0]["what"], "category": clash[0]["category"]}))
            return 2
        for r in clash:
            d["off"][r["original"]] = f"{r['category']}: {r['what']}"
        d["added"] = [x for x in d["added"] if norm(x["keys"]) != n] + [{"keys": a[1], "command": a[2], "description": a[3]}]
    elif cmd == "remove" and len(a) >= 2:
        d["added"] = [x for x in d["added"] if norm(x["keys"]) != norm(a[1])]
    else:
        print(__doc__)
        return 1
    save(d)
    print(json.dumps({"ok": True, "errors": reload()}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
