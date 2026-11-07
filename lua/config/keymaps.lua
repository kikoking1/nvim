-- Non-plugin keymaps. Plugin-specific maps live next to each plugin spec.

local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("i", "<C-c>", "<Esc>", { desc = "Exit insert mode" })

-- Save like :w, VS Code style, staying in the current mode. Cmd+S arrives as
-- <D-s> on macOS, or with the Super key in terminals that pass it through
-- (Ghostty, WezTerm with the kitty keyboard protocol). Replaces Neovim's
-- default insert-mode <C-s> (LSP signature help). Not in terminal mode, so
-- the shell still gets Ctrl+S.
map({ "n", "i", "x", "s" }, "<C-s>", "<Cmd>write<CR>", { desc = "Save buffer" })
map({ "n", "i", "x", "s" }, "<D-s>", "<Cmd>write<CR>", { desc = "Save buffer" })

-- System clipboard
map({ "n", "x" }, "<leader>p", '"+gP', { desc = "Paste from system clipboard" })
map({ "n", "x" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
map("n", "<leader>Y", [["+Y]], { desc = "Yank line to system clipboard" })
map({ "n", "x" }, "<leader>d", [["_d]], { desc = "Delete to black-hole register" })

-- Move visual selection up/down
map("x", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("x", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Terminal: escape goes back to normal mode in the terminal window
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Terminal: enter normal mode" })

-- Quickfix toggle (open last list, or close if open)
map("n", "<leader>qf", function()
	for _, win in pairs(vim.fn.getwininfo()) do
		if win.quickfix == 1 then
			vim.cmd("cclose")
			return
		end
	end
	vim.cmd("botright copen")
end, { desc = "Toggle quickfix list" })

-- Copy current buffer's absolute path to clipboard. (Was <leader>fc, which
-- telescope's git_status mapping silently overrode.)
map("n", "<leader>cp", function()
	local filepath = vim.fn.expand("%:p")
	vim.fn.setreg("+", filepath)
	vim.fn.setreg('"', filepath)
end, { desc = "[C]opy buffer [P]ath" })
