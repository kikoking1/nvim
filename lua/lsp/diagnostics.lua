-- Diagnostics presentation. Inline virtual text is off by default and can be
-- toggled per buffer via the keymap defined in lsp/on_attach.lua.

vim.diagnostic.config({
  virtual_text = false,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", source = "if_many" },
})
