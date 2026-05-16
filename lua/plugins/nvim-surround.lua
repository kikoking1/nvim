return {
	"kylechui/nvim-surround",
	version = "*",
	event = "VeryLazy",
	config = function()
		-- Defaults: ys/ds/cs (add/delete/change surrounds), visual S / gS (line-wise),
		-- insert <C-g>s / <C-g>S. Override via setup({ keymaps = { ... }, surrounds = { ... } }).
		require("nvim-surround").setup({})
	end,
}
