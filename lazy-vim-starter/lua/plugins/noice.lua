return {
  "folke/noice.nvim",
  opts = {
    lsp = {
      -- basedpyright/ruff re-analyze on every completion request (not just
      -- debounced text changes), spamming this view during normal typing
      progress = { enabled = false },
    },
  },
}
