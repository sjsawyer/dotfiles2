# tmux

[oh-my-tmux](https://github.com/gpakosz/.tmux) plus personal overrides in `tmux.conf.local`.
`bin/fiscal-quarter` (repo root) feeds the fiscal-quarter status bar segment.

## Setup (macOS)

```bash
brew install tmux fzf jq reattach-to-user-namespace

# oh-my-tmux itself (this repo only holds the overrides)
git clone https://github.com/gpakosz/.tmux.git ~/.tmux
ln -s -f .tmux/.tmux.conf ~/.tmux.conf

# overrides + helper script (adjust the path if this repo isn't at ~/dotfiles2)
ln -s -f ~/dotfiles2/tmux/tmux.conf.local ~/.tmux.conf.local
mkdir -p ~/bin && ln -s -f ~/dotfiles2/bin/fiscal-quarter ~/bin/fiscal-quarter

# Claude-session resume hooks (logs are written next to the links, outside this repo)
mkdir -p ~/.config/tmux-claude-resume
ln -s -f ~/dotfiles2/tmux/claude-resume/save.sh ~/.config/tmux-claude-resume/save.sh
ln -s -f ~/dotfiles2/tmux/claude-resume/restore.sh ~/.config/tmux-claude-resume/restore.sh
```

Start `tmux`. tpm installs tmux-resurrect and tmux-continuum on first launch (needs network + git).
Once that has finished, link the no-op save strategy into the plugin and restart tmux:

```bash
ln -s -f ~/dotfiles2/tmux/resurrect/none.sh ~/.tmux/plugins/tmux-resurrect/save_command_strategies/none.sh
```

(Until it exists resurrect silently falls back to its slow default `ps` strategy.)

## Terminal setup

- **Alt bindings** (`M-h/j/k/l`, `M-Arrow`): in iTerm2 set Profiles > Keys > Left Option key to `Esc+`.
  `iterm2/apply-settings.sh` also adds the Shift+Enter binding and keeps the Solarized profiles consistent (see `iterm2/README.md`).
- **Status bar separators** need a Powerline-patched font, otherwise they render as boxes.

## Notes

- Prefix is `C-a` (`C-b` is unbound). Reload with `C-a r`.
- Copy mode: `v` selects, plus `iw` / `iW` (word / non-whitespace WORD) as vim-style text objects.
- Sessions: continuum auto-saves hourly (`@continuum-save-interval '60'`, in minutes; `0` disables). Save manually with `~/.tmux/plugins/tmux-resurrect/scripts/save.sh`, restore with `C-a R` (it also runs automatically when the server starts).
- Resurrect save strategy: `@resurrect-save-command-strategy 'none'` (`resurrect/none.sh`) skips resurrect's per-pane `ps`,
  which took ~3 minutes for ~180 panes. It loses nothing because panes start via `reattach-to-user-namespace`, so the
  capture only ever saw `-bash`. The script's comments explain how to restore programs like nvim in future.
- Claude resume (`claude-resume/`): `save.sh` runs after every resurrect save and records which Claude Code session is
  in which pane (from `~/.claude/sessions/<pid>.json`; needs `jq`). `restore.sh` runs after a restore and types
  `claude --resume <id>` plus the original flags into those panes. `@claude-resume-mode`: `run` (default, presses Enter,
  staggered) or `type` (leaves Enter to you). Panes that are busy, gone, or whose directory is missing are skipped.
  Logs: `~/.config/tmux-claude-resume/{save,restore}.log`. Preview a restore with `DRY_RUN=1 ~/.config/tmux-claude-resume/restore.sh`.
- Window names: `automatic-rename` is off (oh-my-tmux turns it on), so restored windows keep their saved names.
- The status bar uses custom variables (`shaundiskfree`, `shauntimeutc`, `shaunfiscalquarter`) defined at the bottom of `tmux.conf.local`.
