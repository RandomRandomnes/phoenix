#!/usr/bin/env python3
"""Settings search index, read from the Settings pages themselves (Phoenix, 2026-10-16).

Prints JSON: [{"title", "page", "sub", "keywords"}] for every card, switch, list and slider in
modules/ii/settingsW11/P*.qml (and the S*.qml pages they include), so the search in Settings and in the Super menu
finds every setting and can jump to it. Replaces a hand-written list of ~90 entries that missed most settings.
page = the category (system, personalization, …), sub = the sub-page ("" = the category's main page), keywords = the
card's description, its hidden `keywords:` (search words the short description left out) and its section.
"""
import json
import os
import re
import sys

HERE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "modules", "ii", "settingsW11")
PAGES = {"PHome": "home", "PSystem": "system", "PDevices": "devices", "PNetwork": "network",
         "PPersonalization": "personalization", "PApps": "apps", "PAccounts": "accounts", "PTime": "time",
         "PGaming": "gaming", "PAccessibility": "accessibility", "PPrivacy": "privacy", "PExtras": "extras",
         "PUpdate": "update"}
# cards whose first title / text is the setting's name (WC* = the original illogical-impulse widgets: `text:`)
CARDS = ("WCard", "WToggle", "WCombo", "WLink", "WSlider", "WTile", "WCSwitch", "WCSpin", "WCSlider", "WCText",
         "WCCombo", "WCSelection", "WCHyprSwitch", "WCHyprSpin", "WCHyprText", "WCHyprSelection", "WCColors")
SECTIONS = ("WSection", "WCSection", "WCSubsection", "WCGroup")
STR = r'(?:"((?:[^"\\]|\\.)*)"|Translation\.tr\("((?:[^"\\]|\\.)*)"\))'


def read(name):
    try:
        with open(os.path.join(HERE, name + ".qml"), encoding="utf-8") as f:
            return f.read()
    except OSError:
        return ""


def block_end(src, start):
    """index just after the } matching the { at src[start] (strings and comments skipped)"""
    depth, i, n = 0, start, len(src)
    while i < n:
        c = src[i]
        if src.startswith("//", i):
            j = src.find("\n", i)
            i = n if j < 0 else j
            continue
        if c in "\"'`":
            j = i + 1
            while j < n and src[j] != c:
                j += 2 if src[j] == "\\" else 1
            i = j + 1
            continue
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    return n


def prop(text, name):
    """the first literal value of `name:` in this element (not in nested elements)"""
    depth = 0
    for m in re.finditer(r"[{}]|\b" + name + r"\s*:\s*" + STR, text):
        tok = m.group(0)
        if tok == "{":
            depth += 1
        elif tok == "}":
            depth -= 1
        elif depth == 1:
            return (m.group(1) or m.group(2) or "").replace('\\"', '"')
    return ""


def scan(src, page, sub, section, out, seen_files):
    """cards in src (a component body or a whole S*.qml page)"""
    pat = re.compile(r"\b(" + "|".join(CARDS + SECTIONS) + r"|S[A-Z]\w+|WWindowRules|WAutostartApps|WReport)\s*\{")
    i = 0
    while True:
        m = pat.search(src, i)
        if not m:
            break
        kind = m.group(1)
        start = m.end() - 1
        end = block_end(src, start)
        body = src[start:end]
        if kind in SECTIONS:
            title = prop(body, "title")
            scan(body[1:-1], page, sub, title or section, out, seen_files)
            i = end
            continue
        if (kind.startswith("S") or kind in ("WWindowRules", "WAutostartApps", "WReport")) and kind not in CARDS:
            if kind not in seen_files and read(kind):
                seen_files.add(kind)
                scan(read(kind), page, sub, section, out, seen_files)
            i = end
            continue
        title = prop(body, "title") or prop(body, "text")
        if title and "${" not in title and len(title) < 90:
            words = " ".join(x for x in (prop(body, "description"), prop(body, "keywords"), section) if x)
            out.append({"title": title, "page": page, "sub": sub, "keywords": words.lower()})
        # cards inside cards (rare) are found too
        scan(body[1:-1], page, sub, section, out, seen_files)
        i = end


def main():
    out = []
    for fname, page in PAGES.items():
        src = read(fname)
        if not src:
            continue
        # which component is which sub-page: sourceComponent: ({ "sub": component, … })[WState.sub] ?? overview
        subs = {}
        m = re.search(r"sourceComponent:\s*\(\{(.*?)\}\)\s*\[WState\.sub\]\s*\?\?\s*(\w+)", src, re.S)
        if m:
            for k, v in re.findall(r'"([\w-]+)"\s*:\s*(\w+)', m.group(1)):
                subs[v] = k
            subs[m.group(2)] = ""
        comps = list(re.finditer(r"\bComponent\s*\{", src))
        if not comps or not subs:
            scan(src, page, "", "", out, set())
            continue
        for c in comps:
            start = c.end() - 1
            end = block_end(src, start)
            body = src[start:end]
            idm = re.search(r"^\s*id:\s*(\w+)", body[1:], re.M)
            if not idm or idm.group(1) not in subs:
                continue
            scan(body[1:-1], page, subs[idm.group(1)], "", out, set())
    seen, uniq = set(), []
    for e in out:
        key = (e["title"].lower(), e["page"], e["sub"])
        if key not in seen:
            seen.add(key)
            uniq.append(e)
    json.dump(uniq, sys.stdout, ensure_ascii=False)
    return 0


if __name__ == "__main__":
    sys.exit(main())
