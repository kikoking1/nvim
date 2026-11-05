-- Bootstrap lazy.nvim and load every spec under lua/plugins/.

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
    }, true, {})
    return
  end
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "plugins" } },
  install = { colorscheme = { "tokyonight" } },
  change_detection = { notify = false },
  -- No plugin here needs luarocks; skipping it avoids the hererocks setup.
  rocks = { enabled = false },
  performance = {
    rtp = {
      -- Built-in runtime plugins this config never uses. netrw is kept so
      -- `nvim <dir>` still opens a file browser (neo-tree is lazy-loaded).
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
