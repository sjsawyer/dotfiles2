#!/bin/sh
# List the tmux sessions for the C-a C-j switcher, most recently accessed first, with how long ago that was.
#
# Output, one line per session:   <session id>  <age>  <name>
#   - <session id> ($3 ...) is what the picker switches to. fzf hides it (--with-nth 2..), which also means a
#     session name containing spaces works.
#   - <age>: time since you last focused a pane in the session: now, 7m, 3h, 2d; "-" when there is no record.
#     Showing it makes a session with no history obviously unranked.
#   - order: @last_access newest first (stamped on a session by the pane-focus-in hook in tmux.conf.local, and saved
#     and restored with the Claude snapshot); sessions with no stamp follow alphabetically.
#
# Env (for tests): SESSION_LIST_NOW overrides the current time (unix seconds).
now="${SESSION_LIST_NOW:-$(date +%s)}"
t="$(printf '\t')"
tmux list-sessions -F "#{session_id}${t}#{?@last_access,#{@last_access},0}${t}#{session_name}" 2>/dev/null |
  sort -t "$t" -k2,2nr -k3,3 |
  awk -F'\t' -v now="$now" '
    function age(s,   d) {
      if (s + 0 <= 0) return "-"
      d = now - s
      if (d < 60) return "now"
      if (d < 3600) return int(d / 60) "m"
      if (d < 172800) return int(d / 3600) "h"
      return int(d / 86400) "d"
    }
    # age is left-aligned: fzf drops the leading padding of the first displayed field, so right-aligning it would
    # leave the names ragged
    { printf "%s  %-4s  %s\n", $1, age($2), $3 }'
