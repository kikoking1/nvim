-- Toggle "maximize" of a terminal split. Stores the original height/width on
-- first toggle so the second toggle can restore them.

local M = {}

local saved_dimensions = nil

local function is_terminal_buffer()
  return vim.bo.buftype == "terminal"
end

function M.maximize_terminal()
  if not is_terminal_buffer() then
    vim.notify("Maximize only works in a terminal window", vim.log.levels.WARN)
    return
  end

  if saved_dimensions then
    vim.cmd("resize " .. saved_dimensions.height)
    vim.cmd("vertical resize " .. saved_dimensions.width)
    saved_dimensions = nil
    return
  end

  saved_dimensions = {
    height = vim.api.nvim_win_get_height(0),
    width = vim.api.nvim_win_get_width(0),
  }
  vim.cmd("wincmd _") -- max height
  vim.cmd("wincmd |") -- max width
end

function M.setup(opts)
  opts = opts or {}
  local keymap = opts.keymap or "<A-e>"

  vim.keymap.set("t", keymap, M.maximize_terminal, { desc = "Toggle maximize terminal window" })
end

return M
