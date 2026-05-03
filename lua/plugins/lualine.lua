return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  opts = {
    options = {
      theme = "horizon",
      globalstatus = true,
      section_separators = "",
      component_separators = "",
    },
    sections = {
      -- path = 1 shows the relative path; previously this was set on
      -- `options` where lualine silently ignored it.
      lualine_c = { { "filename", path = 1 } },
    },
  },
}
