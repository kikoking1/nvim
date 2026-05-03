-- LSP keymaps and per-buffer features wired up on LspAttach.

local M = {}

local function buf_map(buf, lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = "LSP: " .. desc })
end

-- Diagnostic navigation lives outside on-attach since it's useful even when
-- no LSP client is attached (e.g. for diagnostics from non-LSP sources).
local function set_global_diagnostic_keymaps()
  local jump = function(count)
    return function()
      vim.diagnostic.jump({ count = count, float = true })
    end
  end
  vim.keymap.set("n", "[d", jump(-1), { desc = "Previous diagnostic" })
  vim.keymap.set("n", "]d", jump(1), { desc = "Next diagnostic" })
end

local function on_attach(event)
  local buf = event.buf
  local client = vim.lsp.get_client_by_id(event.data.client_id)
  if not client then
    return
  end

  local telescope = require("telescope.builtin")

  buf_map(buf, "<leader>li", telescope.lsp_implementations, "[I]mplementation")
  buf_map(buf, "<leader>ld", telescope.lsp_definitions, "[D]efinition")
  buf_map(buf, "<leader>lr", telescope.lsp_references, "[R]eferences")
  buf_map(buf, "<leader>lt", telescope.lsp_type_definitions, "[T]ype definition")
  buf_map(buf, "<leader>ls", telescope.lsp_document_symbols, "Document [S]ymbols")
  buf_map(buf, "<leader>lR", vim.lsp.buf.rename, "[R]ename")
  buf_map(buf, "<leader>la", vim.lsp.buf.code_action, "Code [A]ction")
  buf_map(buf, "<leader>lD", vim.lsp.buf.declaration, "Goto [D]eclaration")
  buf_map(buf, "K", function()
    vim.lsp.buf.hover({ border = "rounded" })
  end, "Hover documentation")

  buf_map(buf, "<leader>le", function()
    local current = vim.diagnostic.config().virtual_text
    vim.diagnostic.config({ virtual_text = not current })
  end, "Toggle diagnostic virtual text")

  buf_map(buf, "<leader>lE", function()
    vim.diagnostic.open_float({ border = "rounded" })
  end, "Show diagnostic in float")

  -- Highlight references of the symbol under the cursor while it idles.
  if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
    local highlight_group = vim.api.nvim_create_augroup("lsp-highlight-" .. buf, { clear = true })
    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
      buffer = buf,
      group = highlight_group,
      callback = vim.lsp.buf.document_highlight,
    })
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
      buffer = buf,
      group = highlight_group,
      callback = vim.lsp.buf.clear_references,
    })
    vim.api.nvim_create_autocmd("LspDetach", {
      buffer = buf,
      group = vim.api.nvim_create_augroup("lsp-detach-" .. buf, { clear = true }),
      callback = function()
        vim.lsp.buf.clear_references()
        pcall(vim.api.nvim_clear_autocmds, { group = highlight_group, buffer = buf })
      end,
    })
  end

  -- Inlay hints: only wire the toggle if the server supports them.
  if client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
    buf_map(buf, "<leader>lh", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }), { bufnr = buf })
    end, "Toggle inlay [H]ints")
  end
end

function M.setup()
  set_global_diagnostic_keymaps()
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
    callback = on_attach,
  })
end

return M
