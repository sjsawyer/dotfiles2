-- return {
--   "maxmx03/solarized.nvim",
--   lazy = false,
--   priority = 1000,
--   ---@type solarized.config
--   opts = {},
--   config = function(_, opts)
--     vim.o.termguicolors = true
--     vim.o.background = "dark"
--     require("solarized").setup(opts)
--     vim.cmd.colorscheme("solarized")
--   end,
-- }


-- TODO find a different solarized theme
return {
  "ishan9299/nvim-solarized-lua",
  lazy = false,
  priority = 1000,
  config = function()
    vim.cmd("colorscheme solarized")
  end,
}

