return {
  "akinsho/toggleterm.nvim",
  version = "*",
  cmd = { "ToggleTerm", "TermExec" },
  opts = {
    direction = "float",
    size = 20,
    close_on_exit = true,
    float_opts = { border = "curved" },
  },
  keys = {
    { "<C-e>", "<cmd>ToggleTerm direction=horizontal<cr>", mode = { "n", "t" }, desc = "Toggle horizontal terminal" },
    { "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Toggle horizontal terminal" },
    { "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "Toggle floating terminal" },
    {
      "<leader>tg",
      function()
        require("toggleterm.terminal").Terminal:new({ cmd = "lazygit", hidden = true }):toggle()
      end,
      desc = "Toggle lazygit",
    },
  },
}
