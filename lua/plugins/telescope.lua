return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.6",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-live-grep-args.nvim", version = "^1.0.0" },
      "nvim-telescope/telescope-ui-select.nvim",
    },
    keys = function()
      local builtin = require("telescope.builtin")

      local function grep_visual()
        -- Yank the visual selection into register `v` without polluting `"`.
        vim.cmd('noau normal! "vy"')
        local text = (vim.fn.getreg("v") or ""):gsub("\n", "")
        vim.fn.setreg("v", {})
        builtin.live_grep({ default_text = text })
      end

      return {
        { "<leader>ff", builtin.find_files, desc = "[F]ind [F]iles" },
        { "<leader>fF", builtin.git_files, desc = "[F]ind [F]iles (git)" },
        { "<leader>fg", builtin.live_grep, desc = "[F]ind [G]rep" },
        { "<leader>fg", grep_visual, mode = "v", desc = "[F]ind [G]rep (selection)" },
        { "<leader>fc", builtin.git_status, desc = "[F]ind [C]hanged files" },
        { "<leader>fk", builtin.keymaps, desc = "[F]ind [K]eymaps" },
        { "<leader>fh", builtin.oldfiles, desc = "[F]ind [H]istory" },
        {
          "<leader>fa",
          function()
            require("telescope").extensions.live_grep_args.live_grep_args()
          end,
          desc = "[F]ind grep with [A]rgs",
        },
      }
    end,
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        extensions = {
          ["ui-select"] = { require("telescope.themes").get_dropdown({}) },
        },
      })
      telescope.load_extension("live_grep_args")
      telescope.load_extension("ui-select")
    end,
  },
}
