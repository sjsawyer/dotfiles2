return {
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
    keys = {
      { "<leader>gD", "<cmd>DiffviewOpen origin/master...HEAD<cr>", desc = "Diff branch vs master" },
      { "<leader>gH", "<cmd>DiffviewFileHistory --range=origin/master...HEAD<cr>", desc = "Branch commits" },
      { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Close diffview" },
    },
  },
}
