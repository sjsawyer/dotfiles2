# Neovim configs

Only what is needed to regenerate each setup is tracked. Plugins,
parsers and language servers are reinstalled from the files below.

## LazyVim (`lazy-vim-starter/`, launched with `viml`)

```sh
ln -s ~/dotfiles2/lazy-vim-starter ~/.config/lazy-vim-starter
NVIM_APPNAME=lazy-vim-starter nvim
```

- `lazy-lock.json` pins every plugin; run `:Lazy restore` to match it.
- `lazyvim.json` lists the enabled extras, which install their own
  language servers (Mason) and treesitter parsers on first start.
- Needs `tree-sitter-cli` installed (`port install tree-sitter-cli`).

## Legacy vim-plug config (`nvim/`, launched with `vim`)

```sh
ln -s ~/dotfiles2/nvim ~/.config/nvim
nvim +PlugInstall +qa
nvim -S ~/.config/nvim/vim-plug/snapshot.vim   # pin plugin versions
```

Then, inside nvim:

```vim
:TSInstall dockerfile python rst terraform toml yaml
```

- `vim-plug/plugins.vim` lists the plugins; `vim-plug/snapshot.vim`
  pins their commits (refresh with `:PlugSnapshot! <path>`).
- coc.nvim extensions install automatically from
  `g:coc_global_extensions` in `plugin-configs/coc.shaun.vim`.
- `autoload/plugged/` holds the downloaded plugins and is git-ignored.
