-- General editor options.

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.expandtab = true

opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.mouse = "a"
opt.termguicolors = true
opt.scrolloff = 8

opt.wrap = true
opt.linebreak = false
opt.swapfile = false
-- With swapfiles off, persistent undo is the safety net for lost edits.
opt.undofile = true

opt.hlsearch = true
opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "split"

opt.splitright = true
opt.splitbelow = true

-- Default is 4000ms, which makes CursorHold (LSP document highlight in
-- lua/lsp/on_attach.lua) and gitsigns feel sluggish.
opt.updatetime = 250

opt.list = true
opt.listchars = { tab = "  ", trail = "·", nbsp = "␣" }
