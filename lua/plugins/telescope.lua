local function builtin(name)
  return function()
    require("telescope.builtin")[name]()
  end
end

return {
  {
    "nvim-telescope/telescope.nvim",
    -- No version pin: tracks master. The old 0.1.x tags call
    -- make_position_params() without position_encoding, which Neovim 0.11+
    -- warns about on LSP pickers.
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-live-grep-args.nvim", version = "^1.0.0" },
      "nvim-telescope/telescope-ui-select.nvim",
    },
    -- Static key specs with lazy `require`s: a `keys = function()` that
    -- requires telescope.builtin up front would load telescope at startup.
    keys = {
      { "<leader>ff", builtin("find_files"), desc = "[F]ind [F]iles" },
      { "<leader>fF", builtin("git_files"), desc = "[F]ind [F]iles (git)" },
      { "<leader>fg", builtin("live_grep"), desc = "[F]ind [G]rep" },
      {
        "<leader>fg",
        function()
          local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() })
          require("telescope.builtin").live_grep({ default_text = table.concat(lines, "") })
        end,
        mode = "x",
        desc = "[F]ind [G]rep (selection)",
      },
      { "<leader>fc", builtin("git_status"), desc = "[F]ind [C]hanged files" },
      { "<leader>fk", builtin("keymaps"), desc = "[F]ind [K]eymaps" },
      { "<leader>fh", builtin("oldfiles"), desc = "[F]ind [H]istory" },
      {
        "<leader>fa",
        function()
          require("telescope").extensions.live_grep_args.live_grep_args()
        end,
        desc = "[F]ind grep with [A]rgs",
      },
    },
    init = function()
      -- telescope-ui-select replaces vim.ui.select once telescope loads. Load
      -- it on the first call so pickers (e.g. the DAP .dll picker, code
      -- actions) get the telescope UI even before any telescope key is used.
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.select = function(...)
        require("lazy").load({ plugins = { "telescope.nvim" } })
        return vim.ui.select(...)
      end
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
