return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPost", "BufNewFile", "BufWritePost" },
	config = function()
		local lint = require("lint")

		lint.linters_by_ft = {
			javascript = { "eslint_d" },
			javascriptreact = { "eslint_d" },
			typescript = { "eslint_d" },
			typescriptreact = { "eslint_d" },
			go = { "golangcilint" },
		}

		-- eslint_d should only run when the project actually has an ESLint
		-- config; otherwise the daemon errors out on every save. Mirrors the
		-- check in conform-autoformatter.lua.
		local function has_eslint_config(dirname)
			local markers = {
				".eslintrc",
				".eslintrc.js",
				".eslintrc.cjs",
				".eslintrc.json",
				".eslintrc.yaml",
				".eslintrc.yml",
				"eslint.config.js",
				"eslint.config.mjs",
				"eslint.config.cjs",
				"eslint.config.ts",
			}
			return vim.fs.find(markers, { upward = true, path = dirname })[1] ~= nil
		end

		local function linters_for(bufnr)
			local ft = vim.bo[bufnr].filetype
			local names = vim.list_extend({}, lint.linters_by_ft[ft] or {})

			-- Drop eslint_d when there's no ESLint config in scope.
			if vim.tbl_contains(names, "eslint_d") then
				local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
				if dir == "" or not has_eslint_config(dir) then
					names = vim.tbl_filter(function(n)
						return n ~= "eslint_d"
					end, names)
				end
			end

			return names
		end

		local function try_lint()
			local bufnr = vim.api.nvim_get_current_buf()
			local names = linters_for(bufnr)
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
