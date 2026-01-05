-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Basedpyright has type hints; override pyright default
vim.g.lazyvim_python_lsp = "basedpyright"

-- Don't format on save (use `<leader>cf` instead)
vim.g.autoformat = false

-- Don't display '-' as trailing space character (TODO highlight instead)
-- N.B. This overrides the defaults.
vim.opt.listchars = {
  tab = "> ",
  -- trail = " ",
  nbsp = "+",
}

-- Reduce lagging for screen redraws (noticed when scrolling quickly for some
-- files)
vim.opt.lazyredraw = true

-- Set scrolloff: start scrolling when you are 'n' characters away from top/bottom
vim.opt.scrolloff = 20
-- Set scrolljump: scroll faster (the number of lines to scroll)
vim.opt.scrolljump = 2

-- Disable animations by default (slows down UI)
vim.g.snacks_animate = false
