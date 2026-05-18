return {
  "seblyng/roslyn.nvim",
  ft = { "cs", "razor", "cshtml" },
  -- The Roslyn LSP itself is installed via Mason (see lua/plugins/lsp-config.lua).
  -- This spec only configures the plugin that drives the server.
  ---@module "roslyn.config"
  ---@type RoslynNvimConfig
  opts = {
    -- "auto" leaves filewatching to Neovim; switch to "roslyn" if Neovim's
    -- filewatcher misbehaves on your platform.
    filewatching = "auto",
    -- Search upward for solutions even if the .sln lives above your cwd.
    broad_search = true,
    silent = false,
    -- Disable the Razor extension. roslyn.nvim's defaults pass
    --   --razorSourceGenerator=... --razorDesignTimePath=...
    -- to the Roslyn server. The Mason-shipped server we use
    -- (`5.8.0-1.26262.10`, Crashdummyy registry) does NOT recognize those
    -- flags and exits with code 1, which kills LSP for all C# files. If
    -- you start working on .razor/.cshtml files and need Razor support,
    -- upgrade the Roslyn package via Mason to a build that accepts those
    -- args, then re-enable this extension.
    extensions = {
      razor = { enabled = false },
    },
  },
  config = function(_, opts)
    -- Per-server settings go through vim.lsp.config; the plugin itself only
    -- consumes the lazy `opts` table above.
    vim.lsp.config("roslyn", {
      settings = {
        ["csharp|background_analysis"] = {
          dotnet_analyzer_diagnostics_scope = "openFiles",
          dotnet_compiler_diagnostics_scope = "openFiles",
        },
        ["csharp|inlay_hints"] = {
          csharp_enable_inlay_hints_for_implicit_object_creation = true,
          csharp_enable_inlay_hints_for_implicit_variable_types = true,
          csharp_enable_inlay_hints_for_lambda_parameter_types = true,
          csharp_enable_inlay_hints_for_types = true,
          dotnet_enable_inlay_hints_for_parameters = true,
        },
        ["csharp|code_lens"] = {
          dotnet_enable_references_code_lens = true,
          dotnet_enable_tests_code_lens = true,
        },
        ["csharp|completion"] = {
          dotnet_show_completion_items_from_unimported_namespaces = true,
        },
        ["csharp|formatting"] = {
          dotnet_organize_imports_on_format = true,
        },
        ["csharp|symbol_search"] = {
          dotnet_search_reference_assemblies = true,
        },
      },
    })

    require("roslyn").setup(opts)
  end,
}
