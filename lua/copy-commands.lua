local M = {}

function M.setup(opts)
	opts = opts or {}
	local keymap = opts.keymap or "<leader>cf"

	vim.keymap.set("n", keymap, function()
		local filepath = vim.fn.expand("%:p")
		vim.fn.setreg("+", filepath) -- Copy to system clipboard
		vim.fn.setreg('"', filepath) -- Copies to the unnamed register, so you can paste with 'p'
	end, { noremap = true, silent = true, desc = "Copy current buffer path" })
end

return M
