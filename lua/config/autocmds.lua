-- Editor-wide autocommands. Plugin-specific ones stay with the plugin.

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

autocmd("TextYankPost", {
  desc = "Briefly highlight yanked text",
  group = augroup("highlight-yank", { clear = true }),
  callback = function()
    -- vim.hl is the new namespace in 0.11+; fall back to vim.highlight.
    local hl = vim.hl or vim.highlight
    hl.on_yank()
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
  -- Refresh the qf window so the cursor stays on a valid entry.
  if #items > 0 then
    vim.cmd(("%d cc"):format(math.min(idx, #items)))
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
