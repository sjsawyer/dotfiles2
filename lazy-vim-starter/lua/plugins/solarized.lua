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
    -- Solarized sets fg on Diff* groups, which overrides syntax colors. Use bg-only tints.
    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = function()
        local dark = vim.o.background == "dark"
        vim.api.nvim_set_hl(0, "DiffAdd",    { bg = dark and "#133a2e" or "#ece9c3" })
        vim.api.nvim_set_hl(0, "DiffChange", { bg = dark and "#05384c" or "#dfe7e1" })
        vim.api.nvim_set_hl(0, "DiffText",   { bg = dark and "#0a435d" or "#c7dbdf" })
        vim.api.nvim_set_hl(0, "DiffDelete", { bg = dark and "#282c35" or "#f7d3c3" })
      end,
    })
    vim.cmd("colorscheme solarized")
  end,
}

