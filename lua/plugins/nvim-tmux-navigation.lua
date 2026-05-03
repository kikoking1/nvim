return {
  "alexghergh/nvim-tmux-navigation",
  event = "VeryLazy",
  opts = {},
  keys = {
    { "<C-h>", "<cmd>NvimTmuxNavigateLeft<cr>", mode = { "n", "t" }, desc = "Navigate left" },
    { "<C-j>", "<cmd>NvimTmuxNavigateDown<cr>", mode = { "n", "t" }, desc = "Navigate down" },
    { "<C-k>", "<cmd>NvimTmuxNavigateUp<cr>", mode = { "n", "t" }, desc = "Navigate up" },
    { "<C-l>", "<cmd>NvimTmuxNavigateRight<cr>", mode = { "n", "t" }, desc = "Navigate right" },
  },
}
