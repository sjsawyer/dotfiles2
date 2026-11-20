#!/usr/bin/env bash
# Snapshot "tmux pane -> Claude Code session" so restore.sh can resume them.
# Runs as the tmux-resurrect @resurrect-hook-post-save-all hook (or manually).
#
# Output: $RESURRECT_DIR/claude_sessions_<save-timestamp>.tsv  (+ claude_sessions_last.tsv symlink)
# Columns: session  window  pane  sessionId  cwd  last_access  flags
#   last_access = unix seconds the pane was last used: the newer of its @focus stamp (set by the pane-focus-in
#   hook) and Claude's last real activity (updatedAt, ignored if within 10s of startedAt, i.e. just a resume).
#   (Also writes $RESURRECT_DIR/session_access_<ts>.tsv: session<TAB>@last_access, for the C-a C-j switcher.)
#   restore.sh writes it back to @focus so the C-a C-n switcher keeps its order across a restart. 0 = never.
# A snapshot with zero sessions never replaces a previous one (e.g. a save on a fresh, empty server).
#
# Speed: everything is joined in ONE awk pass (ps table + tmux panes + one bulk jq read), so cost scales
# with the number of Claude sessions, not with the number of tmux panes.
set -u

RDIR="${RESURRECT_DIR:-$HOME/.tmux/resurrect}"
SDIR="${CLAUDE_SESSIONS_DIR:-$HOME/.claude/sessions}"
PDIR="${CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}"
LOG="${CLAUDE_RESUME_LOG:-$HOME/.config/tmux-claude-resume/save.log}"
KEEP=10

log() {
  mkdir -p "$(dirname "$LOG")"
  { [ -f "$LOG" ] && tail -n 200 "$LOG"; echo "$(date '+%F %T') $*"; } > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
}

[ -d "$RDIR" ] || { log "no resurrect dir $RDIR"; exit 0; }
command -v jq >/dev/null || { log "jq missing"; exit 0; }

last_target="$(readlink "$RDIR/last" 2>/dev/null || true)"
ts="$(basename "${last_target:-tmux_resurrect_manual.txt}" .txt)"; ts="${ts#tmux_resurrect_}"
out="$RDIR/claude_sessions_${ts}.tsv"
tmp="$(mktemp "$RDIR/.claude_sessions.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

# Args after the claude binary, minus resume/continue/session flags and positional prompts.
extract_flags() {
  awk '
    BEGIN { found = 0; skipnext = 0
      split("--model --permission-mode --add-dir --settings --mcp-config --append-system-prompt --agent --effort --allowedTools --disallowedTools --allowed-tools --disallowed-tools --fallback-model --output-style", v, " ")
      for (i in v) takes[v[i]] = 1 }
    { for (i = 1; i <= NF; i++) {
        if (!found) { if ($i ~ /(claude(\.exe)?|cli\.js)$/) found = 1; continue }
        t = $i
        if (skipnext) { skipnext = 0; if (t !~ /^-/) continue }
        if (t == "--resume" || t == "-r" || t == "--session-id") { skipnext = 1; continue }
        if (t ~ /^--resume=/ || t ~ /^--session-id=/ || t == "--continue" || t == "-c" || t == "--fork-session") continue
        if (t ~ /^-/) { printf "%s ", t; if (t in takes) { i++; if (i <= NF) printf "%s ", $i } }
      } }'
}

# Inputs, each gathered with a single command:
PSTAB="$(ps -axo pid=,ppid=)"                                                       # pid ppid
PANES="$(tmux list-panes -a -F "#{pane_pid}"$'\t'"#{session_name}"$'\t'"#{window_index}"$'\t'"#{pane_index}"$'\t'"#{@focus}" 2>/dev/null || true)"
SESS="$(jq -r '[(input_filename | split("/") | last | rtrimstr(".json")), (.sessionId // ""), (.cwd // ""), (.updatedAt // 0), (.startedAt // 0)] | @tsv' \
          "$SDIR"/*.json 2>/dev/null || true)"                                       # pid sessionId cwd updatedAt startedAt
PIDS=""; for f in "$SDIR"/*.json; do [ -e "$f" ] || continue; b="${f##*/}"; PIDS+="${b%.json}"$'\n'; done

# Walk each Claude pid up its parent chain to the tmux pane that owns it (first match per pane wins).
rows="$(awk '
  FILENAME == ARGV[1] { ppid[$1] = $2; next }
  FILENAME == ARGV[2] { split($0, a, "\t"); pane[a[1]] = a[2] "\t" a[3] "\t" a[4]; pfocus[a[1]] = a[5]; next }
  FILENAME == ARGV[3] { split($0, s, "\t"); info[s[1]] = s[2] "\t" s[3]; upd[s[1]] = s[4]; st[s[1]] = s[5]; next }
  { p = $1; hops = 0
    while (p != "" && p != 0 && hops++ < 30) {
      if (p in pane) {
        if (!(pane[p] in seen)) {
          seen[pane[p]] = 1
          f = (pfocus[p] ~ /^[0-9]+$/) ? pfocus[p] + 0 : 0                               # last focus stamp
          r = (($1 in upd) && upd[$1] - st[$1] > 10000) ? int(upd[$1] / 1000) : 0        # real activity, not a resume
          if (r > f) f = r
          printf "%s\t%d\t%s\t%s\n", pane[p], f, $1, (($1 in info) ? info[$1] : "\t")
        }
        break
      }
      p = ppid[p]
    } }
' <(printf '%s\n' "$PSTAB") <(printf '%s\n' "$PANES") <(printf '%s\n' "$SESS") <(printf '%s' "$PIDS"))"

n=0; skipped=0
while IFS=$'\t' read -r sname widx pidx last cpid sid cwd; do
  [ -n "${cpid:-}" ] || continue
  if [ -z "${sid:-}" ]; then  # not in the bulk read (e.g. caught mid-write): read it directly
    IFS=$'\t' read -r sid cwd < <(jq -r '[.sessionId // "", .cwd // ""] | @tsv' "$SDIR/$cpid.json" 2>/dev/null)
  fi
  [ -n "${sid:-}" ] && [ -n "${cwd:-}" ] || continue
  if ! compgen -G "$PDIR/*/$sid.jsonl" >/dev/null; then skipped=$((skipped+1)); continue; fi  # nothing to resume yet
  flags="$(ps -o args= -p "$cpid" 2>/dev/null | extract_flags | sed 's/ *$//')"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$sname" "$widx" "$pidx" "$sid" "$cwd" "${last:-0}" "$flags" >> "$tmp"
  n=$((n+1))
done <<<"$rows"

if [ "$n" -gt 0 ]; then
  mv "$tmp" "$out"; trap - EXIT
  ln -sf "$(basename "$out")" "$RDIR/claude_sessions_last.tsv"
  ls -t "$RDIR"/claude_sessions_2*.tsv 2>/dev/null | tail -n +$((KEEP+1)) | while read -r old; do rm -f "$old"; done
  log "saved $n claude sessions (skipped $skipped without transcript) -> $(basename "$out")"
else
  log "no claude sessions found (skipped $skipped without transcript); kept previous snapshot"
fi

# Session recency stamps for the C-a C-j switcher: the pane-focus-in hook sets @last_access (unix seconds) on a
# session whenever you focus a pane in it. Saved next to the Claude snapshot (same timestamp, same retention);
# restore.sh puts them back. Independent of the Claude snapshot. An empty list never replaces a previous one.
sa="$RDIR/session_access_${ts}.tsv"; satmp="$(mktemp "$RDIR/.session_access.XXXXXX")"
tmux list-sessions -F "#{session_name}"$'\t'"#{@last_access}" 2>/dev/null | awk -F'\t' '$2 ~ /^[0-9]+$/ && $2 + 0 > 0' > "$satmp"
if [ -s "$satmp" ]; then
  mv "$satmp" "$sa"
  ln -sf "$(basename "$sa")" "$RDIR/session_access_last.tsv"
  ls -t "$RDIR"/session_access_2*.tsv 2>/dev/null | tail -n +$((KEEP+1)) | while read -r old; do rm -f "$old"; done
  log "saved $(wc -l < "$sa" | tr -d ' ') session stamps -> $(basename "$sa")"
else
  rm -f "$satmp"
  log "no session stamps yet; kept previous snapshot"
fi
echo "claude sessions saved: $n (skipped $skipped)"
