return {
  {
    "stevearc/conform.nvim",
    opts = {
      -- Other conform options...
      formatters = {
        ruff = {
          -- Tell ruff to use single quotes
          prepend_args = { "--config 'quote-style=single'" },
          -- alternatively, can specify a path to a config file, for example:
          -- prepend_args = { "--config=/Users/shaun/.config/ruff/format.toml" },
        },
        -- Other formatters...
      },
    },
  },
}
