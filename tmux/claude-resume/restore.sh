#!/usr/bin/env bash
# Resume Claude Code sessions in restored tmux panes, using the snapshot written by save.sh.
# Runs as the tmux-resurrect @resurrect-hook-post-restore-all hook, or manually.
#
# Mode (tmux option @claude-resume-mode, or env CLAUDE_RESUME_MODE):
#   run  (default) type the command and press Enter, staggered
#   type           type the command but leave Enter to you
# Also restores the switchers' recency stamps: @last_access on sessions (C-a C-j) and @focus on Claude panes (C-a C-n).
# Env: DRY_RUN=1 only prints; CLAUDE_BIN, CLAUDE_MAP, SESSION_MAP, RESURRECT_DIR, CLAUDE_RESUME_STAGGER override defaults.
set -u

RDIR="${RESURRECT_DIR:-$HOME/.tmux/resurrect}"
CLAUDE_BIN="${CLAUDE_BIN:-claude}"
STAGGER="${CLAUDE_RESUME_STAGGER:-1}"
DRY="${DRY_RUN:-0}"
MODE="${CLAUDE_RESUME_MODE:-$(tmux show -gqv @claude-resume-mode 2>/dev/null)}"; MODE="${MODE:-run}"

say() { echo "$(date '+%F %T') $*"; }

last_target="$(readlink "$RDIR/last" 2>/dev/null || true)"
ts="$(basename "${last_target:-x}" .txt)"; ts="${ts#tmux_resurrect_}"
# The snapshot written for this save (named after resurrect's save timestamp), else its *_last.tsv link.
pick() {
  if   [ -f "$RDIR/$1_${ts}.tsv" ]; then echo "$RDIR/$1_${ts}.tsv"
  elif [ -f "$RDIR/$1_last.tsv" ];  then echo "$RDIR/$1_last.tsv"
  fi
}

# Focus-wise the restore is over once the saved stamps are back: let the pane-focus-in hook stamp panes again.
# (It skips stamping while the pre-restore hook's @restoring flag is set, because a restore moves focus through
# every window; the flag also expires on its own after 5 minutes.)
end_focus_pause() { [ "$DRY" = 1 ] || tmux set-option -gu @restoring 2>/dev/null; }

# Session stamps (the C-a C-j switcher's order): put each saved @last_access back on its session. Needs no Claude
# snapshot. Never overwrites a newer stamp.
smap="${SESSION_MAP:-$(pick session_access)}"
restored_sessions=0
if [ -n "$smap" ] && [ -f "$smap" ]; then
  while IFS=$'\t' read -r sname stamp; do
    [[ "$stamp" =~ ^[0-9]+$ ]] && [ "$stamp" -gt 0 ] || continue
    tmux has-session -t "=$sname" 2>/dev/null || continue
    # (set-option/show-options want "=name:" with the trailing colon; plain "=name" is rejected there)
    have="$(tmux show-options -qv -t "=$sname:" @last_access 2>/dev/null)"
    if ! [[ "$have" =~ ^[0-9]+$ ]] || [ "$have" -lt "$stamp" ]; then
      if [ "$DRY" = 1 ]; then say "would set @last_access=$stamp on session $sname"
      else tmux set-option -t "=$sname:" @last_access "$stamp"; fi
      restored_sessions=$((restored_sessions+1))
    fi
  done < "$smap"
fi
say "session last-access stamps restored: $restored_sessions"

map="${CLAUDE_MAP:-$(pick claude_sessions)}"
[ -n "$map" ] && [ -f "$map" ] || { end_focus_pause; say "no claude snapshot found in $RDIR"; exit 0; }
say "restoring from $(basename "$map") mode=$MODE dry=$DRY"

[ "$DRY" = 1 ] || sleep "${CLAUDE_RESUME_STARTUP_WAIT:-2}"   # let restored shells come up

# Snapshot rows: session window pane sessionId cwd last_access flags. Older snapshots have no last_access column,
# so then the "last_access" field actually holds the flags: shuffle them back.
fix_cols() {
  if [ -n "${last:-}" ] && ! [[ "$last" =~ ^[0-9]+$ ]]; then flags="$last${flags:+ $flags}"; last=0; fi
  last="${last:-0}"
}

# Pass 1 (fast, before the staggered resumes): put each pane's saved last-access time back into @focus, so the
# Claude switcher (C-a C-n) keeps its order across a restart. Never overwrites a newer stamp.
stamped=0
while IFS=$'\t' read -r s w p sid cwd last flags; do
  [ -n "$sid" ] || continue
  fix_cols
  [ "$last" -gt 0 ] || continue
  pane="$(tmux display-message -p -t "=$s:$w.$p" '#{pane_id}' 2>/dev/null)" || pane=""
  [ -n "$pane" ] || continue
  have="$(tmux show-options -pqv -t "$pane" @focus 2>/dev/null)"
  if ! [[ "$have" =~ ^[0-9]+$ ]] || [ "$have" -lt "$last" ]; then
    if [ "$DRY" = 1 ]; then say "would set @focus=$last on $s:$w.$p"
    else tmux set-option -p -t "$pane" @focus "$last"; fi
    stamped=$((stamped+1))
  fi
done < "$map"
say "last-access stamps restored: $stamped"
end_focus_pause

# Pass 2: resume the Claude sessions.
ok=0; skip=0
while IFS=$'\t' read -r s w p sid cwd last flags; do
  [ -n "$sid" ] || continue
  fix_cols
  tgt="=$s:$w.$p"
  pane="$(tmux display-message -p -t "$tgt" '#{pane_id}' 2>/dev/null)" || pane=""
  if [ -z "$pane" ]; then say "skip $s:$w.$p - pane not found"; skip=$((skip+1)); continue; fi
  cur="$(tmux display-message -p -t "$pane" '#{pane_current_command}')"
  if ! [[ "$cur" =~ ^-?(ba|z|fi)?sh$ || "$cur" == reattach-to-user-namespace ]]; then
    say "skip $s:$w.$p - pane busy ($cur)"; skip=$((skip+1)); continue
  fi
  if ! [[ "$sid" =~ ^[0-9a-fA-F-]{36}$ ]]; then say "skip $s:$w.$p - bad session id"; skip=$((skip+1)); continue; fi
  [[ "$flags" =~ ^[A-Za-z0-9\ _=.,:/@+-]*$ ]] || flags=""
  if [ ! -d "$cwd" ]; then say "skip $s:$w.$p - cwd gone ($cwd)"; skip=$((skip+1)); continue; fi
  line="$CLAUDE_BIN --resume $sid${flags:+ $flags}"
  pcwd="$(tmux display-message -p -t "$pane" '#{pane_current_path}')"
  [ "$pcwd" = "$cwd" ] || line="cd -- $(printf '%q' "$cwd") && $line"
  if [ "$DRY" = 1 ]; then say "would send to $s:$w.$p: $line"
  else
    tmux send-keys -t "$pane" -l -- "$line"
    [ "$MODE" = type ] || tmux send-keys -t "$pane" Enter
    say "sent to $s:$w.$p ($MODE): $line"
    sleep "$STAGGER"
  fi
  ok=$((ok+1))
done < "$map"
say "done: $ok handled, $skip skipped"
