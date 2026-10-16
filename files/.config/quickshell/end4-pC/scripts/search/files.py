#!/usr/bin/env python3
"""File search for the Super search's Files mode (Phoenix P13, 2026-10-16, ours; not upstream).

  files.py serve          read one query per line on stdin, answer one JSON line each:
                          {"q": query, "results": [{"path", "name", "dir", "isDir", "recent"}]}
  files.py query <text>   one answer, for testing

No indexer needed: the home folder is scanned in memory (shallow folders first, hidden folders skipped, at most
MAX_ENTRIES names, so a big game library can't crowd out documents) and scanned again when the index is older than
REFRESH seconds. Files you opened recently (~/.local/share/recently-used.xbel) come first.
"""
import json
import os
import re
import sys
import threading
import time
import urllib.parse
from collections import deque

HOME = os.path.expanduser("~")
MAX_ENTRIES = 80000
MAX_DEPTH = 6
REFRESH = 300
LIMIT = 20
SKIP = {"node_modules", "__pycache__", "venv", "lost+found", "compatdata", "shadercache", "steamapps", "drive_c", "pfx"}
# your personal folders rank above everything else in home (build trees, game files)
PERSONAL = tuple(os.path.join(HOME, d) + os.sep for d in ("Desktop", "Documents", "Downloads", "Pictures", "Videos", "Music", "Projects"))
RECENT = os.path.join(os.environ.get("XDG_DATA_HOME") or os.path.join(HOME, ".local/share"), "recently-used.xbel")

_index = []          # [(lower name, path, isDir, depth)]
_built = 0.0
_lock = threading.Lock()


def build():
    out = []
    q = deque([(HOME, 0)])
    while q and len(out) < MAX_ENTRIES:
        d, depth = q.popleft()
        try:
            with os.scandir(d) as it:
                for e in it:
                    if e.name.startswith("."):
                        continue
                    try:
                        is_dir = e.is_dir(follow_symlinks=False)
                    except OSError:
                        continue
                    out.append((e.name.lower(), e.path, is_dir, depth))
                    if is_dir and depth + 1 < MAX_DEPTH and e.name not in SKIP:
                        q.append((e.path, depth + 1))
        except OSError:
            continue
    return out


def ensure_index():
    global _index, _built
    with _lock:
        if not _index or time.time() - _built > REFRESH:
            _index = build()
            _built = time.time()
    return _index


def recent_files():
    try:
        with open(RECENT, errors="ignore") as f:
            text = f.read()
    except OSError:
        return []
    items = re.findall(r'<bookmark href="file://([^"]+)"[^>]*modified="([^"]+)"', text)
    items.sort(key=lambda x: x[1], reverse=True)
    out = []
    for href, _ in items:
        p = urllib.parse.unquote(href)
        if p not in out and os.path.exists(p):
            out.append(p)
    return out[:200]


def search(query):
    words = query.lower().split()
    if not words:
        return []
    recent = recent_files()
    recent_set = {p: i for i, p in enumerate(recent)}
    scored = []
    seen = set()

    def score(name, path, is_dir, depth):
        if not all(w in name for w in words):
            return None
        s = depth * 2 + len(name) / 40
        if name.startswith(words[0]):
            s -= 3
        if path.startswith(PERSONAL):
            s -= 4
        if path in recent_set:
            s -= 20 - recent_set[path] / 20
        return s

    for p in recent:
        n = os.path.basename(p).lower()
        sc = score(n, p, os.path.isdir(p), p.count(os.sep) - HOME.count(os.sep))
        if sc is not None:
            scored.append((sc, p, os.path.isdir(p)))
            seen.add(p)
    for name, path, is_dir, depth in ensure_index():
        if path in seen:
            continue
        sc = score(name, path, is_dir, depth)
        if sc is not None:
            scored.append((sc, path, is_dir))
    scored.sort(key=lambda x: x[0])
    res = []
    for _, p, is_dir in scored[:LIMIT]:
        d = os.path.dirname(p)
        res.append({"path": p, "name": os.path.basename(p), "dir": "~" + d[len(HOME):] if d.startswith(HOME) else d,
                    "isDir": is_dir, "recent": p in recent_set})
    return res


def main():
    a = sys.argv[1:]
    if a[:1] == ["query"]:
        print(json.dumps({"q": " ".join(a[1:]), "results": search(" ".join(a[1:]))}, indent=1))
        return 0
    if a[:1] == ["serve"]:
        threading.Thread(target=ensure_index, daemon=True).start()   # warm up while the user types
        for line in sys.stdin:
            q = line.rstrip("\n")
            try:
                out = {"q": q, "results": search(q)}
            except Exception as e:
                out = {"q": q, "results": [], "error": str(e)}
            print(json.dumps(out), flush=True)
        return 0
    print(__doc__)
    return 1


if __name__ == "__main__":
    sys.exit(main())
