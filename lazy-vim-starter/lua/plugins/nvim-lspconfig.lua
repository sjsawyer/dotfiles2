return {
  "neovim/nvim-lspconfig",
  ---@class LspConfig
  opts = {
    servers = {
      -- existing servers...
      basedpyright = {
        settings = {
          basedpyright = {
            analysis = {
              diagnosticSeverityOverrides = {
                reportAny = "none",
                reportExplicitAny = "none",
                reportUnannotatedClassAttribute = "none",
                reportUnknownArgumentType = "none",
                reportUnknownMemberType = "none",
                reportUnknownVariableType = "none",
              },
            },
          },
        },
      },
      -- Python formatting runs through the ruff LSP (not conform). Default to
      -- single quotes, but let a project's own ruff config take precedence.
      ruff = {
        init_options = {
          settings = {
            configurationPreference = "filesystemFirst",
            configuration = { format = { ["quote-style"] = "single" } },
          },
        },
      },
      -- terraformls = {
      --   -- This function tells the LSP server where to find the project root.
      --   root_dir = function(fname)
      --     local lspconfig = require("lspconfig")
      --     -- Check for .terraform/ or .git/ as root markers, prioritizing .terraform/
      --     return lspconfig.util.root_pattern(
      --       ".terraform", -- Check for this first (your module directory)
      --       ".git"        -- Fallback to the git root (the repo root)
      --     )(fname)
      --   end,
      --   -- Optional: Add extra settings if needed
      --   settings = {
      --     terraform = {
      --       -- ... other settings ...
      --     }
      --   }
      -- },
    },
  },
}
