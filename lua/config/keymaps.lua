-- Non-plugin keymaps. Plugin-specific maps live next to each plugin spec.

local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("i", "<C-c>", "<Esc>", { desc = "Exit insert mode" })

-- System clipboard
map({ "n", "v" }, "<leader>p", '"+gP', { desc = "Paste from system clipboard" })
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
map("n", "<leader>Y", [["+Y]], { desc = "Yank line to system clipboard" })
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete to black-hole register" })

-- Move visual selection up/down
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Terminal: escape goes back to normal mode in the terminal window
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Terminal: enter normal mode" })

-- Quickfix toggle (open last list, or close if open)
map("n", "<leader>q", function()
  for _, win in pairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then
      vim.cmd("cclose")
      return
    end
  end
  vim.cmd("botright copen")
end, { desc = "Toggle quickfix list" })

-- Copy current buffer's absolute path to clipboard
map("n", "<leader>cf", function()
  local filepath = vim.fn.expand("%:p")
  vim.fn.setreg("+", filepath)
  vim.fn.setreg('"', filepath)
end, { desc = "Copy current buffer path" })
