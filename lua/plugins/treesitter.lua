return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	opts = { ensure_installed = { "c_sharp", "html", "jsx", "tsx", "javascript" } },
	config = function()
		local configs = require("nvim-treesitter.configs")

		configs.setup({
			auto_install = true,
			highlight = { enable = true },
			indent = { enable = true },
		})
	end,
}
