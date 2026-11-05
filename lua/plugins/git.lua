return {
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "Gvdiffsplit" },
    keys = {
      { "<leader>gs", "<cmd>Git<cr>", desc = "[G]it [S]tatus" },
      { "<leader>gd", "<cmd>Gvdiffsplit<cr>", desc = "[G]it [D]iff" },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
    keys = {
      { "<leader>gh", "<cmd>Gitsigns preview_hunk<cr>", desc = "[G]it preview [H]unk" },
      { "<leader>gb", "<cmd>Gitsigns toggle_current_line_blame<cr>", desc = "[G]it toggle [B]lame" },
      -- stage_hunk toggles: on an already-staged hunk it unstages it.
      { "<leader>gS", "<cmd>Gitsigns stage_hunk<cr>", desc = "[G]it [S]tage/unstage hunk" },
      {
        "<leader>gS",
        function()
          require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end,
        mode = "x",
        desc = "[G]it [S]tage/unstage selected lines",
      },
    },
  },
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFileHistory" },
    keys = {
      { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "[G]it diff[V]iew open" },
      { "<leader>gV", "<cmd>DiffviewClose<cr>", desc = "[G]it diff[V]iew close" },
      { "<leader>gl", "<cmd>DiffviewFileHistory<cr>", desc = "[G]it [L]og (repo history)" },
      { "<leader>gL", "<cmd>DiffviewFileHistory %<cr>", desc = "[G]it [L]og (current file)" },
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        merge_tool = { layout = "diff3_mixed" },
      },
    },
  },
}
