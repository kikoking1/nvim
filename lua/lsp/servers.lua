-- Per-server LSP overrides. Keys are server names as known to mason-lspconfig
-- and nvim-lspconfig. Values are partial vim.lsp.config tables (settings,
-- filetypes, root_markers, etc.) merged on top of nvim-lspconfig defaults.

return {
  gopls = {
    settings = {
      gopls = {
        analyses = { unusedparams = true, shadow = true },
        staticcheck = true,
        gofumpt = true,
        usePlaceholders = true,
        completeUnimported = true,
        semanticTokens = true,
        linksInHover = false,
      },
    },
  },

  vtsls = {
    -- Listed explicitly so we can extend filetypes elsewhere if needed.
    filetypes = {
      "javascript",
      "javascriptreact",
      "javascript.jsx",
      "typescript",
      "typescriptreact",
      "typescript.tsx",
    },
    settings = {
      vtsls = {
        enableMoveToFileCodeAction = true,
        autoUseWorkspaceTsdk = true,
        experimental = {
          completion = { enableServerSideFuzzyMatch = true },
        },
      },
      typescript = {
        updateImportsOnFileMove = { enabled = "always" },
        suggest = { completeFunctionCalls = true },
        inlayHints = {
          enumMemberValues = { enabled = true },
          functionLikeReturnTypes = { enabled = true },
          parameterNames = { enabled = "literals" },
          parameterTypes = { enabled = true },
          propertyDeclarationTypes = { enabled = true },
          variableTypes = { enabled = false },
        },
      },
    },
  },

  lua_ls = {
    settings = {
      Lua = {
        completion = { callSnippet = "Replace" },
        -- Silence noisy "missing-fields" warnings on plugin opts tables.
        diagnostics = { disable = { "missing-fields" } },
      },
    },
  },

  -- The Prisma LSP also handles `.prisma` schema formatting, so we let
  -- conform.nvim fall through to the LSP for `prisma` files.
  prismals = {},

  -- C# uses roslyn.nvim instead of omnisharp; configured in
  -- lua/plugins/roslyn.lua (and via vim.lsp.config("roslyn", ...) there).
}
