return {
	"alexghergh/nvim-tmux-navigation",
	config = function()
		require("nvim-tmux-navigation").setup({})
		vim.keymap.set({ "n", "t" }, "<C-h>", "<Cmd>NvimTmuxNavigateLeft<CR>", {})
		vim.keymap.set({ "n", "t" }, "<C-j>", "<Cmd>NvimTmuxNavigateDown<CR>", {})
		vim.keymap.set({ "n", "t" }, "<C-k>", "<Cmd>NvimTmuxNavigateUp<CR>", {})
		vim.keymap.set({ "n", "t" }, "<C-l>", "<Cmd>NvimTmuxNavigateRight<CR>", {})
	end,
}
