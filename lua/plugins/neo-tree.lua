return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	cmd = "Neotree",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	keys = {
		{ "<leader>nn", "<cmd>Neotree toggle left<cr>", desc = "[N]eotree [T]oggle" },
		{ "<leader>nf", "<cmd>Neotree reveal<cr>", desc = "[N]eotree reveal current [F]ile" },
	},
	opts = {
		filesystem = {
			window = {
				mappings = {
					-- Mapping "fg" to our custom grep command below
					["fg"] = "telescope_grep",
					-- Mapping "ff" to our custom find files command below
					["ff"] = "telescope_find",
				},
			},
			commands = {
				telescope_grep = function(state)
					local node = state.tree:get_node()
					local path = node:get_id()
					if node.type ~= "directory" then
						path = node:get_parent_id()
					end

					require("telescope.builtin").live_grep({
						search_dirs = { path },
						prompt_title = string.format("Grep in [%s]", vim.fn.fnamemodify(path, ":t")),
					})
				end,
				telescope_find = function(state)
					local node = state.tree:get_node()
					local path = node:get_id()
					if node.type ~= "directory" then
						path = node:get_parent_id()
					end

					require("telescope.builtin").find_files({
						search_dirs = { path },
						prompt_title = string.format("Find in [%s]", vim.fn.fnamemodify(path, ":t")),
					})
				end,
			},
		},
	},
}
