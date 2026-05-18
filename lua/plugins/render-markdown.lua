-- In-buffer markdown prettifier: heading icons, code-block backgrounds,
-- bullets, checkboxes, callouts, tables, LaTeX, etc.
--
-- Notes:
--   * Treesitter parsers `markdown` and `markdown_inline` are ensured in
--     lua/plugins/treesitter.lua, which is required by this plugin.
--   * `ft` is honored by lazy.nvim and matches the plugin's own
--     `file_types` default; gitcommit is included because the plugin
--     injects markdown into commit messages out of the box.
--   * Completions for callouts (`[!NOTE]`, …) and checkboxes are wired
--     through the in-process LSP source, which blink.cmp picks up
--     automatically — no extra source registration needed.
return {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = { "markdown", "gitcommit" },
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
	cmd = { "RenderMarkdown" },
	---@module "render-markdown"
	---@type render.md.UserConfig
	opts = {
		completions = { lsp = { enabled = true } },
		-- `n`/`c`/`t` only by default: editing in insert/visual mode shows
		-- the raw markdown source, which is what you usually want.
		render_modes = { "n", "c", "t" },
		-- LaTeX requires the `latex` treesitter parser plus `utftex` or
		-- `pylatexenc` on $PATH. Neither is installed here, and the
		-- healthcheck warns about it; turn it off explicitly.
		latex = { enabled = false },
		heading = {
			sign = false,
			icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
			width = "block",
			left_pad = 1,
			right_pad = 2,
			min_width = 60,
		},
		code = {
			sign = false,
			width = "block",
			min_width = 60,
			left_pad = 1,
			right_pad = 2,
			border = "thin",
		},
		bullet = {
			icons = { "●", "○", "◆", "◇" },
		},
		checkbox = {
			unchecked = { icon = "󰄱 " },
			checked = { icon = "󰱒 " },
		},
		dash = { width = 80 },
		pipe_table = { preset = "round" },
	},
	keys = {
		{ "<leader>rm", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle [R]ender [M]arkdown" },
		{ "<leader>rb", "<cmd>RenderMarkdown buf_toggle<cr>", desc = "Toggle [R]ender Markdown ([B]uffer)" },
	},
}
