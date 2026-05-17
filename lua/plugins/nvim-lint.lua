return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPost", "BufNewFile", "BufWritePost" },
	config = function()
		local lint = require("lint")

		-- ESLint is intentionally absent here: the eslint LSP (configured in
		-- lua/lsp/servers.lua) publishes diagnostics natively, which is faster
		-- and matches VSCode's architecture.
		lint.linters_by_ft = {
			go = { "golangcilint" },
		}

		local function try_lint()
			local bufnr = vim.api.nvim_get_current_buf()
			local names = lint.linters_by_ft[vim.bo[bufnr].filetype] or {}
			if #names > 0 then
				lint.try_lint(names)
			end
		end

		local group = vim.api.nvim_create_augroup("nvim-lint", { clear = true })
		vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
			group = group,
			callback = try_lint,
		})

		vim.keymap.set("n", "<leader>ll", try_lint, { desc = "[L]int buffer" })
	end,
}
