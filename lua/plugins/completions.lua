return {
	"saghen/blink.cmp",
	-- Use a tagged release so we get the precompiled fuzzy-matcher binary.
	-- Without a versioned release lazy.nvim would clone `main` and we'd have
	-- to `cargo build --release` ourselves.
	version = "*",
	event = "InsertEnter",
	dependencies = {
		{
			"L3MON4D3/LuaSnip",
			build = (function()
				if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
					return
				end
				return "make install_jsregexp"
			end)(),
		},
	},
	---@module "blink.cmp"
	---@type blink.cmp.Config
	opts = {
		-- Mirror the old nvim-cmp keymap: `<CR>` accepts, `<C-n>`/`<C-p>`
		-- navigate, `<C-b>`/`<C-f>` scroll docs, `<C-Space>` opens the menu,
		-- `<C-l>`/`<C-h>` step through snippet placeholders.
		keymap = {
			preset = "none",
			["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
			["<CR>"] = { "accept", "fallback" },
			["<C-e>"] = { "hide", "fallback" },
			["<C-n>"] = { "select_next", "fallback" },
			["<C-p>"] = { "select_prev", "fallback" },
			["<C-f>"] = { "scroll_documentation_down", "fallback" },
			["<C-b>"] = { "scroll_documentation_up", "fallback" },
			["<C-l>"] = { "snippet_forward", "fallback" },
			["<C-h>"] = { "snippet_backward", "fallback" },
		},
		snippets = { preset = "luasnip" },
		sources = {
			default = { "lsp", "snippets", "path", "buffer" },
		},
		completion = {
			-- Match the old completeopt = "menu,menuone,noinsert" behaviour:
			-- show the menu but don't auto-insert until the user picks.
			list = { selection = { preselect = false, auto_insert = false } },
			menu = { border = "rounded" },
			documentation = {
				auto_show = true,
				auto_show_delay_ms = 200,
				window = { border = "rounded" },
			},
		},
		signature = { enabled = true, window = { border = "rounded" } },
	},
	opts_extend = { "sources.default" },
}
