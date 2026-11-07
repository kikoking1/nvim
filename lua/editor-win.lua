-- Picks the window to show a file in when something outside the editor area
-- asks (the debugger stopping on a line, a git diff): one already showing the
-- buffer, else the code window used last. Never neo-tree, the bottom panel or
-- other special windows (neo-tree swaps its own buffer back in, which breaks
-- e.g. nvim-dap's jump to the stopped line).

local M = {}

function M.is_code_win(win)
	if vim.api.nvim_win_get_config(win).relative ~= "" then
		return false
	end
	local buf = vim.api.nvim_win_get_buf(win)
	-- the dashboard counts: it's what fills the editor area at startup
	return vim.bo[buf].buftype == "" or vim.bo[buf].filetype == "alpha"
end

local last = nil
vim.api.nvim_create_autocmd("WinEnter", {
	callback = function()
		local win = vim.api.nvim_get_current_win()
		if M.is_code_win(win) then
			last = win
		end
	end,
})

-- A code window in the current tab: showing bufnr if any, else the last used.
function M.find(bufnr)
	local wins = vim.api.nvim_tabpage_list_wins(0)
	if bufnr then
		for _, win in ipairs(wins) do
			if vim.api.nvim_win_get_buf(win) == bufnr then
				return win
			end
		end
	end
	if last and vim.api.nvim_win_is_valid(last) and M.is_code_win(last) and vim.tbl_contains(wins, last) then
		return last
	end
	for _, win in ipairs(wins) do
		if M.is_code_win(win) then
			return win
		end
	end
end

-- Show bufnr in a code window, making one if only special windows are open,
-- and focus it. Returns the window.
function M.show(bufnr)
	local win = M.find(bufnr)
	if win then
		vim.api.nvim_win_set_buf(win, bufnr)
		vim.api.nvim_set_current_win(win)
		return win
	end
	for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "neo-tree" then
			-- split off the right of neo-tree, then give neo-tree its width back
			local width = 40
			pcall(function()
				width = require("neo-tree").config.window.width
			end)
			win = vim.api.nvim_open_win(bufnr, true, { split = "right", win = w })
			vim.api.nvim_win_set_width(w, width)
			return win
		end
	end
	return vim.api.nvim_open_win(bufnr, true, { split = "above", win = -1 })
end

return M
