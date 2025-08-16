return {
	{
		"folke/tokyonight.nvim",
		lazy = false,
		name = "tokyonight",
		priority = 1000,
		config = function()
			require("tokyonight").setup()
			vim.cmd.colorscheme("tokyonight")
		end,
	},
}
