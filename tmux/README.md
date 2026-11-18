# tmux

[oh-my-tmux](https://github.com/gpakosz/.tmux) plus personal overrides in `tmux.conf.local`.
`bin/fiscal-quarter` (repo root) feeds the fiscal-quarter status bar segment.

## Setup (macOS)

```bash
brew install tmux fzf reattach-to-user-namespace

# oh-my-tmux itself (this repo only holds the overrides)
git clone https://github.com/gpakosz/.tmux.git ~/.tmux
ln -s -f .tmux/.tmux.conf ~/.tmux.conf

# overrides + helper script (adjust the path if this repo isn't at ~/dotfiles2)
ln -s -f ~/dotfiles2/tmux/tmux.conf.local ~/.tmux.conf.local
mkdir -p ~/bin && ln -s -f ~/dotfiles2/bin/fiscal-quarter ~/bin/fiscal-quarter
```

Start `tmux`. tpm installs tmux-resurrect and tmux-continuum on first launch (needs network + git).

## Terminal setup

- **Alt bindings** (`M-h/j/k/l`, `M-Arrow`): in iTerm2 set Profiles > Keys > Left Option key to `Esc+`.
- **Status bar separators** need a Powerline-patched font, otherwise they render as boxes.

## Notes

- Prefix is `C-a` (`C-b` is unbound). Reload with `C-a r`.
- Copy mode: `v` selects, plus `iw` / `iW` (word / non-whitespace WORD) as vim-style text objects.
- Sessions: continuum auto-save is off. Save manually with `~/.tmux/plugins/tmux-resurrect/scripts/save.sh`, restore with `C-a R`.
- The status bar uses custom variables (`shaundiskfree`, `shauntimeutc`, `shaunfiscalquarter`) defined at the bottom of `tmux.conf.local`.
