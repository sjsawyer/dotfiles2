#!/usr/bin/env bash
# No-op "save command strategy" for tmux-resurrect (selected in ~/.tmux.conf.local with
#   set -g @resurrect-save-command-strategy 'none').
#
# WHY: the default strategy (ps.sh) runs `ps -ao ppid,args | sed | grep | cut` once PER PANE. Here one
# such `ps` takes ~0.9s (mostly kernel time), so saving ~184 panes took ~3 minutes and pegged the CPU.
# The captured value was useless anyway: panes start via `reattach-to-user-namespace`, so a pane's
# direct child is always the interactive `-bash`; resurrect never sees nvim/claude/etc., and `-bash`
# is not on @resurrect-processes, so nothing was ever restored from it. Skipping the capture restores
# exactly the same things and takes a save from ~195s to ~12s.
#
# FUTURE (to actually bring back programs that die on restart, e.g. nvim/htop/claude): capture the real
# foreground program instead of the pane's direct child, cheaply:
#   - either drop the reattach-to-user-namespace wrapper (likely unneeded on modern macOS) so the pane's
#     shell is the direct process and the program is its child (then even ps.sh would work); or
#   - write a strategy that takes ONE shared `ps -axo pid=,ppid=` snapshot (no args, ~0.1s), walks down
#     the pane's process tree, and fetches args only for the leaf with `ps -o args= -p <pid>`;
#   then list the programs in @resurrect-processes (e.g. 'nvim htop', or '"~claude->claude --continue"').
# Claude sessions are already resumed separately by ~/.config/tmux-claude-resume/.
exit 0
