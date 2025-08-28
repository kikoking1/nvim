return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.6",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local builtin = require("telescope.builtin")

			-- for auto populating grep search with current selected text
			local function get_visual_selection()
				vim.cmd('noau normal! "vy"')
				local text = vim.fn.getreg("v")
				vim.fn.setreg("v", {})

				text = string.gsub(text, "\n", "")
				if #text > 0 then
					return text
				else
					return ""
				end
			end

			local function grep_string_visual()
				local text = get_visual_selection()
				builtin.live_grep({ default_text = text })
			end

			vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "[F]ind [F]iles All" })
			vim.keymap.set("n", "<leader>fF", builtin.git_files, { desc = "[F]ind [F]iles Git" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "[F]ind [G]rep" })
			vim.keymap.set("v", "<leader>fg", grep_string_visual, { desc = "[F]ind [G]rep with selection" })
			vim.keymap.set("n", "<leader>fc", builtin.git_status, { desc = "[F]ind [C]hanged files (git)" })
			vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "[F]ind [K]eymaps" })
			vim.keymap.set("n", "<leader>fh", builtin.oldfiles, { desc = "[F]ind [H]istory" })
		end,
	},
	{
		"nvim-telescope/telescope-ui-select.nvim",
		config = function()
			require("telescope").setup({
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
				},
			})
			require("telescope").load_extension("ui-select")
		end,
	},
}
