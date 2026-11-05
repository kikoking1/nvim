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
    -- Ctrl+` (the ~ key), VS Code style. Terminals report it differently: as
    -- <C-`>, or with Shift held as <C-~> / <C-S-`>, so all three are mapped.
    -- Needs a terminal that sends distinct Ctrl+key codes (kitty keyboard
    -- protocol): Ghostty does by default, WezTerm via `enable_kitty_keyboard`
    -- in .wezterm.lua. Without it, Ctrl+` is sent as NUL (same as Ctrl+Space).
    { "<C-`>", "<cmd>ToggleTerm direction=horizontal<cr>", mode = { "n", "t" }, desc = "Toggle horizontal terminal" },
    { "<C-~>", "<cmd>ToggleTerm direction=horizontal<cr>", mode = { "n", "t" }, desc = "Toggle horizontal terminal" },
    { "<C-S-`>", "<cmd>ToggleTerm direction=horizontal<cr>", mode = { "n", "t" }, desc = "Toggle horizontal terminal" },
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
