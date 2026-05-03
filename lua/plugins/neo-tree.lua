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
}
