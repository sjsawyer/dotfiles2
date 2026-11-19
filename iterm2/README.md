# iTerm2

iTerm2 keeps its settings inside its own preferences, so there is no config file to symlink.
`apply-settings.sh` re-applies the tweaks that matter for tmux and Claude Code on a new machine.

```bash
~/dotfiles2/iterm2/apply-settings.sh --dry-run   # show what would change
~/dotfiles2/iterm2/apply-settings.sh --quit      # apply (quits and relaunches iTerm2 if needed)
```

What it sets (idempotent, see the script header for the reasoning):

- **Shift+Return** (global key binding) sends `0x1b 0x0d`, i.e. Esc+Enter, so Shift+Enter inserts a newline in
  Claude Code, including inside tmux. iTerm2 otherwise sends a plain Enter for Shift+Return.
- **Solarized Light** gets the same non-colour settings as **Solarized Dark** (both Option keys = `Esc+`, same
  font), so the profiles differ only in colours. `Esc+` is what the tmux `M-` bindings need.

Notes:

- Profile edits only stick while iTerm2 is not running, hence `--quit` (tmux and its Claude sessions keep
  running; run `tmux attach` afterwards). The global key binding is picked up live.
- It assumes profiles named `Solarized Dark` and `Solarized Light` exist; otherwise the profile step is skipped.
- Before changing anything it writes `~/iterm2-prefs-backup-<timestamp>.plist` (`--no-backup` to skip).
- The profile settings themselves (colours, fonts, the 24 key mappings) are not captured here.
