return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>f",
      function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      mode = { "n", "v" },
      desc = "[F]ormat buffer",
    },
  },
  opts = function()
    -- ESLint integrates as a formatter via eslint_d --fix-to-stdout. Only run it
    -- when the project actually defines an ESLint config; otherwise eslint_d
    -- noisily errors on every save.
    local function has_eslint_config(_, ctx)
      local markers = {
        ".eslintrc",
        ".eslintrc.js",
        ".eslintrc.cjs",
        ".eslintrc.json",
        ".eslintrc.yaml",
        ".eslintrc.yml",
        "eslint.config.js",
        "eslint.config.mjs",
        "eslint.config.cjs",
        "eslint.config.ts",
      }
      return vim.fs.find(markers, { upward = true, path = ctx.dirname })[1] ~= nil
    end

    local web = { "eslint_d", "prettier", stop_after_first = false }

    return {
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Languages without a canonical style: don't fall back to LSP formatter.
        local skip_lsp_fallback = { c = true, cpp = true, javascript = true, javascriptreact = true, typescript = true, typescriptreact = true }
        local ft = vim.bo[bufnr].filetype
        return {
          timeout_ms = 2000,
          lsp_fallback = not skip_lsp_fallback[ft],
        }
      end,
      formatters_by_ft = {
        lua = { "stylua" },
        cs = { "csharpier" },
        prisma = { "prisma-fmt" },
        javascript = web,
        javascriptreact = web,
        typescript = web,
        typescriptreact = web,
      },
      formatters = {
        csharpier = {
          command = "dotnet-csharpier",
          args = { "--write-stdout" },
        },
        ["prisma-fmt"] = {
          command = "prisma-fmt",
          stdin = false,
        },
        eslint_d = {
          timeout = 2000,
          condition = has_eslint_config,
        },
      },
    }
  end,
}
