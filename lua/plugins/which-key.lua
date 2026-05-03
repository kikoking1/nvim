return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    spec = {
      { "<leader>l", group = "[L]SP" },
      { "<leader>f", group = "[F]ind (telescope)" },
      { "<leader>g", group = "[G]it" },
      { "<leader>n", group = "[N]eotree" },
      { "<leader>t", group = "[T]erminal" },
      { "<leader>c", group = "[C]opy" },
      { "<leader>d", group = "[D]ebug" },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer-local keymaps (which-key)",
    },
  },
}
