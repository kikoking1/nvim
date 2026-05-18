return {
	"folke/tokyonight.nvim",
	lazy = false,
	priority = 1000,
	-- Add your transparency preferences here
	opts = {
		transparent = true, -- Strips the background from the main code windows
		styles = {
			sidebars = "transparent", -- Makes file managers (like Neo-tree/Nvim-Tree) transparent
			floats = "transparent", -- Makes popups and floating windows transparent
		},
	},
	config = function(_, opts)
		require("tokyonight").setup(opts)
		vim.cmd.colorscheme("tokyonight")
	end,
}
