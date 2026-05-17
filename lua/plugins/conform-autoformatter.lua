return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>f",
			function()
				require("conform").format({ async = true, lsp_fallback = true })
			end,
			mode = { "n", "v" },
			desc = "[F]ormat buffer",
		},
	},
	opts = {
		notify_on_error = false,
		format_on_save = function(bufnr)
			-- Languages without a canonical style: don't fall back to the LSP
			-- formatter when no conform formatter applies. (We don't want
			-- vtsls's TS formatter stepping on prettier's output.)
			local skip_lsp_fallback = {
				c = true,
				cpp = true,
				javascript = true,
				javascriptreact = true,
				typescript = true,
				typescriptreact = true,
			}
			return {
				timeout_ms = 2000,
				lsp_fallback = not skip_lsp_fallback[vim.bo[bufnr].filetype],
			}
		end,
		formatters_by_ft = {
			lua = { "stylua" },
			cs = { "csharpier" },
			-- prisma intentionally omitted: format_on_save above falls through
			-- to the prismals LSP, which handles .prisma formatting itself.
			-- JS/TS: prettierd only. ESLint fixes happen via the eslint LSP's
			-- BufWritePre hook in lua/lsp/on_attach.lua, not here.
			javascript = { "prettierd" },
			javascriptreact = { "prettierd" },
			typescript = { "prettierd" },
			typescriptreact = { "prettierd" },
		},
		formatters = {
			csharpier = {
				command = "dotnet-csharpier",
				args = { "--write-stdout" },
			},
		},
	},
}
