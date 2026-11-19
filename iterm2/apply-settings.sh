#!/usr/bin/env bash
# Re-apply iTerm2 preference tweaks that live inside iTerm2's own prefs (there is no dotfile for them).
#
#   1. Global key binding: Shift+Return -> "Send Hex Code" 0x1b 0x0d (Esc+Enter).
#      Why: iTerm2 sends a plain Enter for Shift+Return even when an app asks for modified keys, so
#      Shift+Enter can't insert a newline in Claude Code (notably inside tmux). Esc+Enter is exactly what
#      Option+Enter sends, which Claude Code treats as "newline". (0x0a, i.e. Ctrl+J, also works.)
#   2. "Solarized Light" gets the same non-colour settings as "Solarized Dark" (both Option keys = Esc+, same
#      font), so the two profiles differ only in colours. Esc+ on the Option keys is required for the tmux
#      M-h/j/k/l / M-Arrow bindings and for Option+Enter.
#
# Idempotent: re-running when everything is already applied changes nothing.
#
# Usage: apply-settings.sh [--dry-run] [--quit] [--no-backup]
#   --dry-run    show what would change, write nothing
#   --quit       profile edits only stick while iTerm2 is NOT running: with --quit the script quits iTerm2,
#                edits the profiles, and relaunches it (tmux keeps running; run `tmux attach` afterwards).
#                Without --quit, profile edits are skipped while iTerm2 is running.
#   --no-backup  don't write ~/iterm2-prefs-backup-<timestamp>.plist before changing anything
#
# The global key binding is read live by iTerm2, so it needs no restart. Env: ITERM_DOMAIN overrides the
# defaults domain (used for testing against a scratch domain).
set -euo pipefail

DOMAIN="${ITERM_DOMAIN:-com.googlecode.iterm2}"
BUNDLE_ID="com.googlecode.iterm2"
KEY="0xd-0x20000"   # Return (0xd) + Shift (0x20000)
HEX="0x1b 0x0d"
DRY=0; QUIT=0; BACKUP=1

for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    --quit) QUIT=1 ;;
    --no-backup) BACKUP=0 ;;
    -h|--help) awk 'NR > 1 { if (/^#/) print; else exit }' "$0"; exit 0 ;;
    *) echo "unknown argument: $a (see --help)" >&2; exit 2 ;;
  esac
done

[ "$(uname)" = Darwin ] || { echo "macOS only" >&2; exit 1; }
command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }

read -r -d '' STATE_PY <<'EOF' || true
import sys, plistlib
key, hexv = sys.argv[1], sys.argv[2]
d = plistlib.loads(sys.stdin.buffer.read())
gk = d.get("GlobalKeyMap", {}).get(key)
print("binding", "ok" if gk and gk.get("Action") == 11 and gk.get("Text") == hexv else "missing")
profs = {p.get("Name"): p for p in d.get("New Bookmarks", [])}
dark, light = profs.get("Solarized Dark"), profs.get("Solarized Light")
if not dark or not light:
    print("profiles absent")
else:
    diffs = [k for k in ("Option Key Sends", "Right Option Key Sends", "Normal Font") if k in dark and light.get(k) != dark.get(k)]
    print("profiles " + ("ok" if not diffs else "differ " + "; ".join("%s: %r -> %r" % (k, light.get(k), dark.get(k)) for k in diffs)))
EOF

read -r -d '' APPLY_PY <<'EOF' || true
import sys, plistlib, subprocess
domain = sys.argv[1]
d = plistlib.loads(subprocess.run(["defaults", "export", domain, "-"], capture_output=True, check=True).stdout)
profs = d["New Bookmarks"]
dark = next(p for p in profs if p.get("Name") == "Solarized Dark")
light = next(p for p in profs if p.get("Name") == "Solarized Light")
for k in ("Option Key Sends", "Right Option Key Sends", "Normal Font"):
    if k in dark:
        light[k] = dark[k]
xml = plistlib.dumps(profs, fmt=plistlib.FMT_XML).decode()
inner = xml.split('<plist version="1.0">', 1)[1].rsplit("</plist>", 1)[0].strip()
subprocess.run(["defaults", "write", domain, "New Bookmarks", inner], check=True)
EOF

BACKUP_DONE=0
backup_once() {
  if [ "$BACKUP" = 1 ] && [ "$BACKUP_DONE" = 0 ]; then
    local f="$HOME/iterm2-prefs-backup-$(date +%Y%m%d-%H%M%S).plist"
    defaults export "$DOMAIN" "$f"
    echo "  backup: $f (safe to delete once you're happy)"
    BACKUP_DONE=1
  fi
  return 0
}

STATE="$(defaults export "$DOMAIN" - | python3 -c "$STATE_PY" "$KEY" "$HEX")"
BINDING="$(printf '%s\n' "$STATE" | awk '$1=="binding"{print $2}')"
PROF="$(printf '%s\n' "$STATE" | sed -n 's/^profiles //p')"

echo "iTerm2 prefs domain: $DOMAIN$([ "$DRY" = 1 ] && echo ' (dry run)')"

# 1. global Shift+Return binding (safe while iTerm2 is running)
if [ "$BINDING" = ok ]; then
  echo "[1] global Shift+Return -> $HEX: already set"
else
  echo "[1] global Shift+Return -> $HEX: will set"
  if [ "$DRY" = 0 ]; then
    backup_once
    defaults write "$DOMAIN" GlobalKeyMap -dict-add "$KEY" \
      "<dict><key>Action</key><integer>11</integer><key>Text</key><string>$HEX</string></dict>"
    echo "    set (iTerm2 reads it live; no restart needed)"
  fi
fi

# 2. Solarized Light matches Solarized Dark
case "$PROF" in
  ok)     echo "[2] Solarized Light already matches Dark (Option keys, font)" ;;
  absent) echo "[2] Solarized Dark/Light profiles not found: skipped" ;;
  differ*)
    echo "[2] Solarized Light differs from Dark: ${PROF#differ }"
    if [ "$DRY" = 1 ]; then
      echo "    (dry run: nothing written)"
    else
      running=0
      if [ "$DOMAIN" = "$BUNDLE_ID" ] && pgrep -x iTerm2 >/dev/null; then running=1; fi
      if [ "$running" = 1 ] && [ "$QUIT" = 0 ]; then
        echo "    SKIPPED: iTerm2 is running, so profile edits would be ignored or overwritten."
        echo "    Re-run with --quit (quits iTerm2, edits, relaunches it; tmux keeps running), or quit iTerm2 first."
      else
        backup_once
        if [ "$running" = 1 ]; then
          echo "    quitting iTerm2..."
          osascript -e 'tell application "iTerm2" to quit' >/dev/null 2>&1 || true
          for _ in $(seq 1 60); do pgrep -x iTerm2 >/dev/null || break; sleep 0.5; done
          if pgrep -x iTerm2 >/dev/null; then
            echo "    iTerm2 did not quit (confirmation dialog?). Nothing written; quit it and re-run." >&2
            exit 3
          fi
        fi
        python3 -c "$APPLY_PY" "$DOMAIN"
        echo "    Solarized Light updated"
        if [ "$running" = 1 ]; then
          open -b "$BUNDLE_ID" && echo "    iTerm2 relaunched: run 'tmux attach' in the new window"
        fi
      fi
    fi
    ;;
esac
echo "done."
