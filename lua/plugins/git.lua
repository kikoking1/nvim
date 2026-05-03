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
    },
  },
}
