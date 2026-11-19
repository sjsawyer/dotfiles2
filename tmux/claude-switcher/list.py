#!/usr/bin/env python3
"""List the Claude Code sessions running in tmux panes, most recently active first, for fzf.

Used by the C-a C-n popup in tmux.conf.local. One line per session:

    <pane_id>  <status> <title>  <session:window.pane>  <cwd>

  - status: a yellow ● while Claude is working, ○ when idle.
  - title:  the latest ai-title from the session transcript (what `claude --resume` shows); falls back to
            Claude's own session name (cwd + hash) when the transcript has none yet.
  - order:  most recently accessed first. "Accessed" is the newer of
              1. when you last focused the pane: the @focus pane option, stamped by the pane-focus-in hook in
                 tmux.conf.local and carried across restarts by claude-resume/save.sh + restore.sh; and
              2. Claude's last real activity: `updatedAt` in ~/.claude/sessions/<pid>.json, but only when it is
                 more than 10s after `startedAt`. A session that was merely (re)started, e.g. resumed by a tmux
                 restore, has updatedAt ~= startedAt; that is not activity and is ignored.
            Sessions with neither sort last, alphabetically by title.

Cheap on purpose: one `tmux list-panes -a`, one small JSON read per session, and only the TAIL of each
transcript (the latest ai-title is always near the end). Titles are cached per transcript (mtime + size)
in ~/.cache, so an unchanged transcript costs a stat().

Sessions are skipped if their process is gone or their pane no longer exists in this tmux server.
~/.claude/sessions is an internal Claude Code format; anything unparsable is ignored, never fatal.

Env overrides (for testing): CLAUDE_SESSIONS_DIR, CLAUDE_PROJECTS_DIR, CLAUDE_SWITCHER_CACHE, TMUX_CMD.
"""
import glob
import json
import os
import re
import shlex
import subprocess
import sys

HOME = os.path.expanduser("~")
SESSIONS_DIR = os.environ.get("CLAUDE_SESSIONS_DIR", f"{HOME}/.claude/sessions")
PROJECTS_DIR = os.environ.get("CLAUDE_PROJECTS_DIR", f"{HOME}/.claude/projects")
CACHE_FILE = os.environ.get("CLAUDE_SWITCHER_CACHE", f"{HOME}/.cache/tmux-claude-switcher/titles.json")
TMUX = shlex.split(os.environ.get("TMUX_CMD", "tmux"))

TAIL_BYTES = (64 * 1024, 1024 * 1024)   # try the last 64KB, then the last 1MB, before giving up
TITLE_KEY = b'"aiTitle":"'
PANE_RE = re.compile(r"%\d+$")
ID_RE = re.compile(r"^[0-9A-Za-z-]+$")
RESUME_GRACE_MS = 10_000                 # updatedAt this close to startedAt means "just (re)started", not activity
TITLE_MAX = 50
CWD_MAX = 36
BUSY = "\033[33m●\033[0m"
IDLE = "○"


def pane_info():
    """{pane_id: ('session:window.pane', last_focus_seconds)} for every pane on this tmux server."""
    r = subprocess.run(
        TMUX + ["list-panes", "-a", "-F",
                "#{pane_id}\t#{session_name}:#{window_index}.#{pane_index}\t#{@focus}"],
        capture_output=True, text=True)
    if r.returncode != 0:
        return {}
    info = {}
    for line in r.stdout.splitlines():
        parts = line.split("\t")
        if len(parts) >= 2:
            focus = parts[2] if len(parts) > 2 and parts[2].isdigit() else "0"
            info[parts[0]] = (parts[1], int(focus))
    return info


def real_activity(s):
    """Claude's last real activity in seconds, or 0 if updatedAt only reflects the session (re)starting."""
    updated = int(s.get("updatedAt") or 0)
    started = int(s.get("startedAt") or 0)
    return updated // 1000 if updated - started > RESUME_GRACE_MS else 0


def alive(pid):
    try:
        os.kill(int(pid), 0)
    except (TypeError, ValueError, OverflowError, ProcessLookupError):
        return False
    except PermissionError:
        return True
    return True


def transcript_path(cwd, session_id):
    if not ID_RE.match(session_id or ""):
        return None
    encoded = "".join(c if c.isalnum() or c == "-" else "-" for c in cwd or "")
    path = f"{PROJECTS_DIR}/{encoded}/{session_id}.jsonl"
    if os.path.exists(path):
        return path
    hits = glob.glob(f"{PROJECTS_DIR}/*/{session_id}.jsonl")
    return hits[0] if hits else None


def parse_json_string(buf, start):
    """Decode the JSON string whose first character (after the opening quote) is at buf[start]."""
    k = start
    while True:
        k = buf.find(b'"', k)
        if k < 0:
            return None                      # closing quote not in this buffer
        backslashes, b = 0, k - 1
        while b >= start and buf[b:b + 1] == b"\\":
            backslashes += 1
            b -= 1
        if backslashes % 2 == 0:
            break                            # an unescaped quote: end of the string
        k += 1
    try:
        return json.loads(b'"' + buf[start:k] + b'"')
    except ValueError:
        return None


def read_title(path):
    """Latest aiTitle in the transcript, reading only its tail. None if there isn't one."""
    size = os.path.getsize(path)
    with open(path, "rb") as fh:
        for n in TAIL_BYTES:
            fh.seek(max(0, size - n))
            buf = fh.read()
            i = buf.rfind(TITLE_KEY)
            if i >= 0:
                title = parse_json_string(buf, i + len(TITLE_KEY))
                if title:
                    return title
            if n >= size:
                break
    return None


def load_cache():
    try:
        with open(CACHE_FILE) as fh:
            data = json.load(fh)
        return data if isinstance(data, dict) else {}
    except (OSError, ValueError):
        return {}


def save_cache(cache):
    try:
        os.makedirs(os.path.dirname(CACHE_FILE), exist_ok=True)
        tmp = f"{CACHE_FILE}.{os.getpid()}"
        with open(tmp, "w") as fh:
            json.dump(cache, fh)
        os.replace(tmp, CACHE_FILE)
    except OSError:
        pass


def clean(text):
    return re.sub(r"[\x00-\x1f\x7f]+", " ", text or "").strip()


def clip(text, width):
    return text if len(text) <= width else text[: width - 1] + "…"


def short_cwd(cwd):
    cwd = clean(cwd)
    if cwd == HOME or cwd.startswith(HOME + "/"):
        cwd = "~" + cwd[len(HOME):]
    return cwd if len(cwd) <= CWD_MAX else "…" + cwd[-(CWD_MAX - 1):]


def main():
    panes = pane_info()
    if not panes:
        return 0

    cache = load_cache()
    fresh = {}
    rows = []
    for path in glob.glob(f"{SESSIONS_DIR}/*.json"):
        try:
            with open(path) as fh:
                s = json.load(fh)
            pane = str(s.get("tmux", "")).rsplit(".", 1)[-1]
            if not PANE_RE.match(pane) or pane not in panes or not alive(s.get("pid")):
                continue
            location, focus = panes[pane]

            title = None
            tpath = transcript_path(s.get("cwd"), s.get("sessionId"))
            if tpath:
                st = os.stat(tpath)
                stamp = [st.st_mtime_ns, st.st_size]
                hit = cache.get(tpath)
                if isinstance(hit, list) and hit[:2] == stamp:
                    title = hit[2]
                else:
                    title = read_title(tpath)
                fresh[tpath] = stamp + [title]

            rows.append({
                "pane": pane,
                "accessed": max(focus, real_activity(s)),
                "busy": s.get("status") == "busy",
                "title": clean(title) or clean(s.get("name")) or "(untitled)",
                "loc": location,
                "cwd": short_cwd(s.get("cwd")),
            })
        except (OSError, ValueError, TypeError, AttributeError):
            continue                          # unreadable / unexpected session file: skip it

    if fresh != cache:
        save_cache(fresh)                     # also drops entries for transcripts that are gone

    rows.sort(key=lambda r: (-r["accessed"], r["title"].lower()))
    title_w = min(TITLE_MAX, max((len(r["title"]) for r in rows), default=0))
    loc_w = max((len(r["loc"]) for r in rows), default=0)
    out = []
    for r in rows:
        out.append(f"{r['pane']}  {BUSY if r['busy'] else IDLE} "
                   f"{clip(r['title'], title_w):<{title_w}}  {r['loc']:<{loc_w}}  {r['cwd']}")
    sys.stdout.write("\n".join(out) + ("\n" if out else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
