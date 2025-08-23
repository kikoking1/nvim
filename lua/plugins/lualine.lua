return {
	"nvim-lualine/lualine.nvim",
	config = function()
		require("lualine").setup({
			options = {
				theme = "horizon",
				path = 1,
			},
		})
	end,
}
