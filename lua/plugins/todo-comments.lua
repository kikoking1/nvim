return {
	"folke/todo-comments.nvim",
	event = { "BufReadPost", "BufNewFile" },
	dependencies = { "nvim-lua/plenary.nvim" },
	cmd = { "TodoTelescope", "TodoQuickFix", "TodoLocList" },
	opts = {
		signs = true,
		highlight = {
			pattern = [[.*<(KEYWORDS)\s*:]],
		},
		search = {
			pattern = [[\b(KEYWORDS):]],
		},
	},
	keys = {
		{
			"]t",
			function()
				require("todo-comments").jump_next()
			end,
			desc = "Next [T]odo comment",
		},
		{
			"[t",
			function()
				require("todo-comments").jump_prev()
			end,
			desc = "Previous [T]odo comment",
		},
		{ "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "[F]ind [T]odos" },
		{
			"<leader>fT",
			"<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>",
			desc = "[F]ind [T]odos (TODO/FIX only)",
		},
	},
}
