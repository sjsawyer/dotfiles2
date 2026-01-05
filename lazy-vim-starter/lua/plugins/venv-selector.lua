return {
  "linux-cultist/venv-selector.nvim",
  cmd = "VenvSelect",
  opts = {
    -- Your optional configuration goes here
    -- For example:
    -- your_option = "value",
  },
  keys = {
    -- Keybindings to open the selector
    { "<leader>cv", "<cmd>VenvSelect<cr>", desc = "Select VirtualEnv" },
  },
}
