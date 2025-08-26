return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	config = function()
		vim.keymap.set("n", "<leader>nn", ":Neotree toggle left<CR>", { desc = "[N]eotree [T]oggle" })
		vim.keymap.set("n", "<leader>nf", ":Neotree reveal<CR>", { desc = "[N]eotree [F]ocus Current File" })
	end,
}
