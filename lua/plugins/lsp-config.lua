return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      -- mason.nvim is configured below (not via `config = true`) so we can
      -- register the Crashdummyy registry that ships the Roslyn LSP package.
      "williamboman/mason.nvim",
      { "williamboman/mason-lspconfig.nvim", version = "^2" },
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      { "j-hui/fidget.nvim", opts = {} },
      { "folke/neodev.nvim", opts = {} },
      "saghen/blink.cmp",
    },
    config = function()
      require("lsp.diagnostics")
      require("lsp.on_attach").setup()

      local servers = require("lsp.servers")

      -- Make completion capabilities the default for every server. blink.cmp
      -- needs this to advertise snippet/completion support to language servers.
      local capabilities = require("blink.cmp").get_lsp_capabilities()
      vim.lsp.config("*", { capabilities = capabilities })

      for name, opts in pairs(servers) do
        vim.lsp.config(name, opts)
      end

      -- The Roslyn C# language server isn't in Mason's core registry; it
      -- ships through Crashdummyy's registry. Both registries must be listed
      -- explicitly because providing `registries` overrides the default.
      require("mason").setup({
        registries = {
          "github:mason-org/mason-registry",
          "github:Crashdummyy/mason-registry",
        },
      })

      -- Tools installed via Mason that aren't LSP servers (formatters, linters,
      -- DAP adapters). Node-based tools require `npm` on PATH; `roslyn` and
      -- `csharpier`/`netcoredbg` require the .NET SDK.
      require("mason-tool-installer").setup({
        ensure_installed = {
          "stylua",
          "prettierd", -- daemonised prettier; eliminates the ~1s Node spinup per save
          "golangci-lint", -- Go linter, driven by nvim-lint
          "csharpier",
          "netcoredbg",
          "roslyn", -- C# LSP, configured by lua/plugins/roslyn.lua
          -- Prisma: prismals (the LSP) is in lua/lsp/servers.lua and handles
          -- formatting itself. There is no separate `prisma-fmt` package.
        },
        run_on_start = true,
      })

      -- mason-lspconfig v2 calls vim.lsp.enable() automatically for any server
      -- it knows is installed, picking up the configs registered above. We
      -- exclude omnisharp explicitly so it never re-attaches alongside roslyn
      -- if the package is ever (re)installed.
      require("mason-lspconfig").setup({
        ensure_installed = vim.tbl_keys(servers),
        automatic_enable = { exclude = { "omnisharp" } },
      })
    end,
  },
}
