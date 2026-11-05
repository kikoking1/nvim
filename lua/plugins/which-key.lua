-- Off by default: which-key isn't loaded until the first <leader>ww, so it
-- doesn't intercept any keys until then. which-key has no API to unload its
-- key triggers, so toggling it back off just stops the popup from appearing.
-- Key sequences still go through which-key and behave the same as before.
local enabled = false

return {
  "folke/which-key.nvim",
  opts = {
    preset = "modern",
    delay = function(ctx)
      if not enabled then
        return 1e9 -- ~11 days: effectively never shows
      end
      return ctx.plugin and 0 or 200
    end,
    spec = {
      { "<leader>l", group = "[L]SP" },
      { "<leader>f", group = "[F]ind (telescope)" },
      { "<leader>g", group = "[G]it" },
      { "<leader>n", group = "[N]eotree" },
      { "<leader>t", group = "[T]erminal" },
      { "<leader>c", group = "[C]opy" },
      { "<leader>d", group = "[D]ebug" },
      { "<leader>r", group = "[R]ender markdown" },
      { "<leader>w", group = "[W]hich-key" },
    },
  },
  keys = {
    {
      "<leader>ww",
      function()
        enabled = not enabled
        -- First press loads the plugin (via this lazy `keys` trigger).
        require("which-key")
        vim.notify("which-key " .. (enabled and "enabled" or "disabled"))
      end,
      desc = "Toggle which-key popup",
    },
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer-local keymaps (which-key)",
    },
  },
}
