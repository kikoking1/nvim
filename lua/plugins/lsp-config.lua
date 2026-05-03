return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "williamboman/mason.nvim", config = true },
      { "williamboman/mason-lspconfig.nvim", version = "^2" },
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      { "j-hui/fidget.nvim", opts = {} },
      { "folke/neodev.nvim", opts = {} },
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      require("lsp.diagnostics")
      require("lsp.on_attach").setup()

      local servers = require("lsp.servers")

      -- Make completion capabilities the default for every server. nvim-cmp
      -- needs this to advertise snippet/completion support to language servers.
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())
      vim.lsp.config("*", { capabilities = capabilities })

      for name, opts in pairs(servers) do
        vim.lsp.config(name, opts)
      end

      require("mason").setup()

      -- Tools installed via Mason that aren't LSP servers (formatters, linters,
      -- DAP adapters). Node-based tools require `npm` on PATH.
      require("mason-tool-installer").setup({
        ensure_installed = {
          "stylua",
          "prettier",
          "eslint_d",
          "csharpier",
          "netcoredbg",
          "prisma-fmt",
        },
        run_on_start = true,
      })

      -- mason-lspconfig v2 calls vim.lsp.enable() automatically for any server
      -- it knows is installed, picking up the configs registered above.
      require("mason-lspconfig").setup({
        ensure_installed = vim.tbl_keys(servers),
        automatic_enable = true,
      })
    end,
  },
}
