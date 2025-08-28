return {
	{ -- Autoformat
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		lazy = false,
		keys = {
			{
				"<leader>f",
				function()
					require("conform").format({ async = true, lsp_fallback = true })
				end,
				mode = "",
				desc = "[F]ormat buffer",
			},
		},
		opts = {
			notify_on_error = false,
			format_on_save = function(bufnr)
				-- Disable "format_on_save lsp_fallback" for languages that don't
				-- have a well standardized coding style. You can add additional
				-- languages here or re-enable it for the disabled ones.
				local disable_filetypes = { c = true, cpp = true }
				return {
					timeout_ms = 2000,
					lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
				}
			end,
			formatters_by_ft = {
				lua = { "stylua" },
				cs = { "csharpier" },
				prisma = { "prisma-fmt" },
				javascript = { "eslint_d", "prettier" },
				javascriptreact = { "eslint_d", "prettier" },
				typescript = { "eslint_d", "prettier" },
				typescriptreact = { "eslint_d", "prettier" },
				-- Conform can also run multiple formatters sequentially
				-- python = { "isort", "black" },
			},
			formatters = {
				csharpier = {
					command = "dotnet-csharpier",
					args = { "--write-stdout" },
				},
				["prisma-fmt"] = {
					command = "prisma-fmt",
					stdin = false,
				},
				eslint_d = {
					timeout = 2000,
				},
			},
		},
	},
}
