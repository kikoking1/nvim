return {
  "nvim-treesitter/nvim-treesitter",
  -- Pin to the legacy `master` branch. The repo's `main` branch is the v1.0
  -- rewrite with a different API (no nvim-treesitter.configs module). Once
  -- the rewrite is stable and ecosystem plugins (autotag, etc.) catch up we
  -- can migrate.
  branch = "master",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  main = "nvim-treesitter.configs",
  opts = {
    auto_install = true,
    highlight = { enable = true },
    indent = { enable = true },
    -- Note: there's no standalone "jsx" parser; "javascript" covers .jsx and
    -- "tsx" covers .tsx.
    ensure_installed = {
      "c_sharp",
      "go",
      "html",
      "tsx",
      "javascript",
      "typescript",
      "lua",
      "vim",
      "vimdoc",
      "prisma",
      "json",
      "yaml",
      "markdown",
    },
  },
}
