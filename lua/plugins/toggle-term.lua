return {
	"akinsho/toggleterm.nvim",
	-- cmd = "ToggleTerm", -- Optional: makes ToggleTerm load immediately, but we can use lazy keys instead
	version = "*", -- use tag 'v2.*' for Neovim 0.7+
	opts = {
		-- Default terminal direction (e.g., "float", "horizontal", "vertical")
		direction = "float",
		-- Size of the terminal (lines for horizontal/vertical, percentage for float)
		size = 20,
		-- Auto-close terminal window on process exit
		close_on_exit = true,
		-- Configure floating window appearance
		float_opts = {
			border = "curved",
		},
		-- ... add other options as desired (see :h toggleterm-setup)
	},
	keys = {
		-- Keymap to toggle the *default* terminal
		{
			"<leader>th",
			"<cmd>ToggleTerm direction=horizontal<cr>",
			desc = "Toggle Horizontal Terminal",
		},
		{
			"<leader>tf",
			"<cmd>ToggleTerm direction=float<cr>",
			desc = "Toggle Floating Terminal",
		},
		-- You can also create keymaps for specific named terminals (e.g., lazygit)
		{
			"<leader>tg",
			function()
				require("toggleterm.terminal").Terminal:new({ cmd = "lazygit", hidden = true }):toggle()
			end,
			desc = "Toggle Lazygit",
		},
	},
	config = function(_, opts)
		require("toggleterm").setup(opts)
	end,
}
