-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local filetype_settings = {
  -- Python
  {
    pattern = "*.py",
    textwidth = 79,
    wrap = true,
    fileformat = "unix",
  },
  -- Java
  {
    pattern = "*.java",
    textwidth = 100,
    wrap = true,
  },
  -- reStructuredText & Markdown
  {
    pattern = { "*.rst", "*.md" },
    textwidth = 80,
    wrap = true,
  },
  -- YAML
  {
    pattern = { "*.y*", "*.yml", "*.yaml", "*.yml.j2", "*.yaml.j2" },
    filetype = "yaml",
    indent = 2,
    wrap = true,
  },
  -- Git Commit Messages
  {
    pattern = "COMMIT_EDITMSG",
    textwidth = 72,
    wrap = true,
  },
  -- Wiki
  {
    pattern = "*.wiki",
    textwidth = 120,
    wrap = false,
  },
  -- SQL
  {
    pattern = { "*.sql", "*.sqltpl", "*.sql.tftpl" },
    filetype = "sql",
  },
}

-- Default Indent if no filetype is determined
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  callback = function()
    -- Set tab width for all files by default
    vim.opt.tabstop = 4
    vim.opt.softtabstop = 4
    vim.opt.shiftwidth = 4
  end,
})

-- Loop through settings and create autocmds
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  callback = function()
    local current_file = vim.fn.expand("%:t")

    for _, settings in ipairs(filetype_settings) do
      -- Check for each pattern
      if type(settings.pattern) == "string" then
        if vim.fn.match(current_file, settings.pattern) ~= -1 then
          goto found
        end
      else
        for _, pat in ipairs(settings.pattern) do
          if vim.fn.match(current_file, pat) ~= -1 then
            goto found
          end
        end
      end
      -- If a pattern is found, apply the settings
      ::found::
      if settings.textwidth then
        vim.opt.textwidth = settings.textwidth
        vim.opt.colorcolumn = tostring(settings.textwidth + 1)
      end
      if settings.wrap ~= nil then
        vim.opt.wrap = settings.wrap
      end
      if settings.filetype then
        vim.opt.filetype = settings.filetype
      end
      if settings.fileformat then
        vim.opt.fileformat = settings.fileformat
      end
      if settings.indent then
        vim.opt.tabstop = settings.indent
        vim.opt.softtabstop = settings.indent
        vim.opt.shiftwidth = settings.indent
      end
      return
    end
  end,
})
