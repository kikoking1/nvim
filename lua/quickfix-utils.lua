function Remove_qf_item()
	-- Get the 1-based line number of the cursor in the quickfix window
	local curqfidx = vim.fn.line(".")
	-- Get the current quickfix list
	local qfall = vim.fn.getqflist()

	-- Return if there are no items
	if #qfall == 0 then
		return
	end

	-- Remove the item from the Lua table (1-based index)
	table.remove(qfall, curqfidx)

	-- Replace the current quickfix list with the modified list ('r' flag)
	vim.fn.setqflist(qfall, "r")

	-- Reopen/refresh the quickfix window to show the change
	-- 'cc' is often used to refresh and center, 'copen' works too.
	vim.cmd("cc")
end

-- Create a user command to call the function
vim.api.nvim_create_user_command("RemoveQFItem", Remove_qf_item, {})

-- Create a buffer-local mapping in the quickfix window
vim.api.nvim_exec(
	[[
  augroup QuickfixCustom
    autocmd!
    autocmd FileType qf nnoremap <buffer> dd :RemoveQFItem<CR>
  augroup END
  ]],
	false
)
