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

-- Smart <Tab>: on a blank (or whitespace-only) line, jump straight to the
-- indent the block expects, computed by 'indentexpr' (treesitter where
-- available), falling back to 'cindent' / the previous non-blank line. If the
-- line already has text or is already at/past that indent, insert a normal Tab.
local function expected_indent(lnum)
	local expr = vim.bo.indentexpr
	if expr ~= "" then
		vim.v.lnum = lnum
		local ok, ind = pcall(vim.fn.eval, expr)
		if ok and tonumber(ind) and tonumber(ind) >= 0 then
			return tonumber(ind)
		end
	end
	if vim.bo.cindent then
		return vim.fn.cindent(lnum)
	end
	local prev = vim.fn.prevnonblank(lnum - 1)
	return prev > 0 and vim.fn.indent(prev) or 0
end

map("i", "<Tab>", function()
	local line = vim.api.nvim_get_current_line()
	if line:match("^%s*$") then
		local lnum = vim.fn.line(".")
		local want = expected_indent(lnum)
		if want > vim.fn.strdisplaywidth(line) then
			local ws
			if vim.bo.expandtab then
				ws = string.rep(" ", want)
			else
				local ts = vim.bo.tabstop
				ws = string.rep("\t", math.floor(want / ts)) .. string.rep(" ", want % ts)
			end
			vim.api.nvim_set_current_line(ws)
			vim.api.nvim_win_set_cursor(0, { lnum, #ws })
			return
		end
	end
	vim.api.nvim_feedkeys(vim.keycode("<Tab>"), "n", false)
end, { desc = "Indent to block level, else Tab" })

-- >> re-indents the line to its block level (like ==) instead of shifting it
-- one 'shiftwidth'. A count re-indents that many lines, like 3==. In visual
-- mode > does the same for the selection (like =).
map("n", ">>", "==", { desc = "Re-indent line to block level" })
map("x", ">", "=", { desc = "Re-indent selection to block level" })

-- Resize the current window: H / L wider / narrower, J / K shorter / taller
-- (a count multiplies the step). A direction the window has no neighbour in
-- is ignored, e.g. J / K on a full-height vsplit (resizing that would grow or
-- shrink the command line instead).
local function resize(dim, delta)
	return function()
		local step = delta * vim.v.count1
		if dim == "width" then
			if vim.fn.winnr("h") ~= vim.fn.winnr() or vim.fn.winnr("l") ~= vim.fn.winnr() then
				vim.api.nvim_win_set_width(0, math.max(1, vim.api.nvim_win_get_width(0) + step))
			end
		elseif vim.fn.winnr("j") ~= vim.fn.winnr() or vim.fn.winnr("k") ~= vim.fn.winnr() then
			vim.api.nvim_win_set_height(0, math.max(1, vim.api.nvim_win_get_height(0) + step))
		end
	end
end
-- Ctrl+Shift+letter needs a terminal that sends it distinctly from
-- Ctrl+letter (kitty keyboard protocol: Ghostty, WezTerm). Others (Ptyxis /
-- VTE) send plain Ctrl+H/J/K/L, which move between windows instead.
for _, key in ipairs({ { "h", "width", 3 }, { "l", "width", -3 }, { "j", "height", -2 }, { "k", "height", 2 } }) do
	local letter, dim, delta = key[1], key[2], key[3]
	local desc = "Resize window: " .. (delta < 0 and "smaller " or "larger ") .. dim
	map({ "n", "t" }, "<C-S-" .. letter .. ">", resize(dim, delta), { desc = desc })
end

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
