#!/usr/bin/env bash
# Resume Claude Code sessions in restored tmux panes, using the snapshot written by save.sh.
# Runs as the tmux-resurrect @resurrect-hook-post-restore-all hook, or manually.
#
# Mode (tmux option @claude-resume-mode, or env CLAUDE_RESUME_MODE):
#   run  (default) type the command and press Enter, staggered
#   type           type the command but leave Enter to you
# Env: DRY_RUN=1 only prints; CLAUDE_BIN, CLAUDE_MAP, RESURRECT_DIR, CLAUDE_RESUME_STAGGER override defaults.
set -u

RDIR="${RESURRECT_DIR:-$HOME/.tmux/resurrect}"
CLAUDE_BIN="${CLAUDE_BIN:-claude}"
STAGGER="${CLAUDE_RESUME_STAGGER:-1}"
DRY="${DRY_RUN:-0}"
MODE="${CLAUDE_RESUME_MODE:-$(tmux show -gqv @claude-resume-mode 2>/dev/null)}"; MODE="${MODE:-run}"

say() { echo "$(date '+%F %T') $*"; }

map="${CLAUDE_MAP:-}"
if [ -z "$map" ]; then
  last_target="$(readlink "$RDIR/last" 2>/dev/null || true)"
  ts="$(basename "${last_target:-x}" .txt)"; ts="${ts#tmux_resurrect_}"
  if   [ -f "$RDIR/claude_sessions_${ts}.tsv" ]; then map="$RDIR/claude_sessions_${ts}.tsv"
  elif [ -f "$RDIR/claude_sessions_last.tsv" ];  then map="$RDIR/claude_sessions_last.tsv"
  fi
fi
[ -n "$map" ] && [ -f "$map" ] || { say "no claude snapshot found in $RDIR"; exit 0; }
say "restoring from $(basename "$map") mode=$MODE dry=$DRY"

[ "$DRY" = 1 ] || sleep "${CLAUDE_RESUME_STARTUP_WAIT:-2}"   # let restored shells come up

# Snapshot rows: session window pane sessionId cwd last_access flags. Older snapshots have no last_access column,
# so then the "last_access" field actually holds the flags: shuffle them back.
fix_cols() {
  if [ -n "${last:-}" ] && ! [[ "$last" =~ ^[0-9]+$ ]]; then flags="$last${flags:+ $flags}"; last=0; fi
  last="${last:-0}"
}

# Pass 1 (fast, before the staggered resumes): put each pane's saved last-access time back into @focus, so the
# Claude switcher (C-a C-e) keeps its order across a restart. Never overwrites a newer stamp.
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
