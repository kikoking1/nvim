-- bottom-terminal.lua
local M = {} -- M is a common convention for the module's table
local terminal_bufnr = nil -- Module-level variable to store the terminal buffer number

-- Function to toggle a terminal window at the bottom
function M.toggle_terminal_bottom()
	-- Try to find the existing terminal window by its stored buffer number
	local existing_terminal_win = nil
	if terminal_bufnr and vim.api.nvim_buf_is_valid(terminal_bufnr) then
		for _, win_id in ipairs(vim.api.nvim_list_wins()) do
			if vim.api.nvim_win_get_buf(win_id) == terminal_bufnr then
				existing_terminal_win = win_id
				break
			end
		end
	end

	if existing_terminal_win then
		-- If the terminal window exists, close it
		vim.api.nvim_win_close(existing_terminal_win, true)
		terminal_bufnr = nil -- Clear the stored buffer number
	else
		-- Otherwise, open a new terminal at the bottom
		vim.cmd("split") -- Create a horizontal split
		vim.cmd("resize -8") -- Make the new window smaller (e.g., 8 lines tall)
		vim.cmd("wincmd J") -- Move the new window to the very bottom
		vim.cmd("terminal") -- Convert the new window into a terminal
		vim.cmd("startinsert!") -- Enter insert mode in the terminal
		terminal_bufnr = vim.api.nvim_get_current_buf() -- Store the new terminal's buffer number
	end
end

-- Function to set up the keymaps
function M.setup_keymaps()
	vim.api.nvim_set_keymap(
		"n",
		"<C-e>",
		':lua require("bottom-terminal").toggle_terminal_bottom()<CR>',
		{ noremap = true, silent = true }
	)

	-- <C-o> temporarily enters Normal mode to execute the command, then returns to Insert mode.
	vim.api.nvim_set_keymap(
		"i",
		"<C-e>",
		'<C-o>:lua require("bottom-terminal").toggle_terminal_bottom()<CR>',
		{ noremap = true, silent = true }
	)

	-- <C-\><C-n> escapes from terminal mode to Normal mode to execute the command.
	vim.api.nvim_set_keymap(
		"t",
		"<C-e>",
		'<C-\\><C-n>:lua require("bottom-terminal").toggle_terminal_bottom()<CR>',
		{ noremap = true, silent = true }
	)
end

return M
