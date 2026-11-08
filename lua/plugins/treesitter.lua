-- nvim-treesitter v1.0 (`main` branch).
--
-- Migration notes:
--   * The `main` branch is a full, incompatible rewrite. There is no
--     `nvim-treesitter.configs` module, no `setup{ highlight = ... }`,
--     and no `auto_install`. Features (highlight, indent, folds) are
--     enabled by the *user*, per-filetype, via `vim.treesitter.start()`.
--   * Upstream explicitly states the plugin does NOT support lazy-loading,
--     hence `lazy = false`. The plugin itself is small; actual treesitter
--     work happens in the FileType autocmd below, so the startup cost is
--     bounded by the filetypes you actually open.
--   * Requires Neovim 0.12+ and `tree-sitter-cli` >= 0.26.1 on $PATH
--     (`pacman -S tree-sitter-cli` / `brew install tree-sitter-cli`).
--
-- Refs: https://github.com/nvim-treesitter/nvim-treesitter/blob/main/README.md
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    local ts = require("nvim-treesitter")

    -- Parsers we want available everywhere. `markdown_inline` is needed
    -- by the `markdown` parser (injected for inline elements); without
    -- it, fenced code blocks/inlines fail to render.
    local ensure = {
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
      "zig",
      "json",
      "yaml",
      "markdown",
      "markdown_inline",
    }

    -- Install any missing parsers from the list. Runs asynchronously;
    -- progress/errors are visible via `:TSLog`.
    local installed = ts.get_installed("parsers")
    local missing = {}
    for _, lang in ipairs(ensure) do
      if not vim.tbl_contains(installed, lang) then
        table.insert(missing, lang)
      end
    end
    if #missing > 0 then
      ts.install(missing)
    end

    -- Enable highlighting + indentation for any buffer whose filetype
    -- maps to an installed parser. This replaces the old
    -- `highlight = { enable = true }` / `indent = { enable = true }`
    -- toggles. Filetype-to-parser mapping (e.g. `cs` -> `c_sharp`,
    -- `typescriptreact` -> `tsx`) is registered by nvim-treesitter's
    -- `plugin/filetypes.lua`, so we just need `get_lang(filetype)`.
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("user-treesitter", { clear = true }),
      callback = function(args)
        local ft = vim.bo[args.buf].filetype
        local lang = vim.treesitter.language.get_lang(ft)
        if not lang then
          return
        end
        -- Silently skip filetypes whose parser isn't installed yet.
        local ok = pcall(vim.treesitter.start, args.buf, lang)
        -- Only take over indenting when the parser ships indent queries.
        -- Some (c_sharp, vim, prisma) don't, and the treesitter indentexpr
        -- then returns 0 for every line, flattening `==` / `>>` to column 0.
        -- Those keep Neovim's own indent/<ft>.vim (e.g. GetCSIndent for C#).
        if ok and vim.treesitter.query.get(lang, "indents") then
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
