return {
	"lukas-reineke/indent-blankline.nvim",
	event = { "BufReadPost", "BufNewFile" },
	main = "ibl",
	---@module "ibl"
	---@type ibl.config
	opts = {
		indent = { char = "│" },
		scope = { show_start = false, show_end = false },
		exclude = {
			filetypes = {
				"help",
				"alpha",
				"dashboard",
				"neo-tree",
				"Trouble",
				"trouble",
				"lazy",
				"mason",
				"notify",
				"toggleterm",
				"lspinfo",
				"checkhealth",
				"gitcommit",
			},
		},
	},
}
