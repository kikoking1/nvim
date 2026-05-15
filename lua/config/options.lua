-- General editor options.

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true

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

opt.wrap = true
opt.linebreak = false
opt.swapfile = false

opt.hlsearch = true
opt.list = true
opt.listchars = { tab = "  ", trail = "·", nbsp = "␣" }
