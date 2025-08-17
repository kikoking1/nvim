local M = {}

-- Store original window dimensions
local original_dimensions = nil

-- Function to check if current buffer is a terminal
local function is_terminal_buffer()
	return vim.bo.buftype == "terminal"
end

-- Function to maximize current window (only in terminal mode)
function M.maximize_terminal()
	if not is_terminal_buffer() then
		vim.notify("Maximize only works in terminal mode", vim.log.levels.WARN)
		return
	end

	if original_dimensions then
		-- Restore original dimensions
		vim.cmd("resize " .. original_dimensions.height)
		vim.cmd("vertical resize " .. original_dimensions.width)
		original_dimensions = nil
		vim.notify("Terminal window restored", vim.log.levels.INFO)
	else
		-- Store current dimensions and maximize
		original_dimensions = {
			height = vim.api.nvim_win_get_height(0),
			width = vim.api.nvim_win_get_width(0),
		}
		vim.cmd("resize")
		vim.cmd("vertical resize")
		vim.notify("Terminal window maximized", vim.log.levels.INFO)
	end
end

-- Setup function to create keymaps
function M.setup(opts)
	opts = opts or {}
	local keymap = opts.keymap or "<A-e>"

	vim.keymap.set("t", keymap, function()
		M.maximize_terminal()
	end, { desc = "Toggle maximize terminal window" })
end

return M

