-- Editor-wide autocommands. Plugin-specific ones stay with the plugin.

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

autocmd("TextYankPost", {
  desc = "Briefly highlight yanked text",
  group = augroup("highlight-yank", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Delete an item from the quickfix list with `dd` while in the qf window.
local function remove_qf_item()
  local idx = vim.fn.line(".")
  local items = vim.fn.getqflist()
  if #items == 0 then
    return
  end
  table.remove(items, idx)
  vim.fn.setqflist(items, "r")
  -- Keep the cursor on a valid entry without jumping out of the qf window
  -- (`:cc` would open the entry and move focus to the file).
  if #items > 0 then
    vim.api.nvim_win_set_cursor(0, { math.min(idx, #items), 0 })
  end
end

vim.api.nvim_create_user_command("RemoveQFItem", remove_qf_item, {})

autocmd("FileType", {
  desc = "Quickfix: dd removes the current item",
  group = augroup("quickfix-bindings", { clear = true }),
  pattern = "qf",
  callback = function(event)
    vim.keymap.set("n", "dd", remove_qf_item, { buffer = event.buf, desc = "Remove quickfix item" })
  end,
})
