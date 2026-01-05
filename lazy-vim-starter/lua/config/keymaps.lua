-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

---- Simplify gq to ignore any set indent and textwidth rules
-- Why? Because our yaml files do not really follow the proper indenting conventions.
-- TODO consider enabling only for yaml?
-- TODO difference between gq and gw?
vim.keymap.set({'n', 'v'}, 'gq', function()
  -- Save the current value of the 'indentexpr' option for the current buffer.
  local original_indentexpr = vim.bo.indentexpr
  local original_formatexpr = vim.bo.formatexpr
  local original_textwidth = vim.bo.textwidth

  -- Temporarily clear the 'indentexpr' option.
  vim.bo.indentexpr = ''
  vim.bo.formatexpr = ''
  vim.bo.textwidth = original_textwidth ~= 0 and original_textwidth or 80

  -- Check if we are in Visual mode.
  if vim.fn.mode() == 'v' then
    -- Use the normal! command to apply the formatting to the visual selection.
    vim.cmd('normal! gvgq')
    -- The `gv` command re-selects the last visual selection.
  else
    -- Execute the default 'gq' command for Normal mode.
    vim.cmd('normal! gq')
  end

  -- Restore the original 'indentexpr' value.
  vim.bo.indentexpr = original_indentexpr
  vim.bo.textwidth = original_textwidth
  vim.bo.formatexpr = original_formatexpr
end, {
  desc = "Simplified text formatting."
})


-- Search for last visual selection.
vim.api.nvim_set_keymap('v', '//', 'y/<C-R>"<CR>', { noremap = true })
