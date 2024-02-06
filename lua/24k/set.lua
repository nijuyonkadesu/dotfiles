vim.opt.guicursor = ""

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
--vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

-- vim.opt.colorcolumn = "80"
vim.g.mapleader = " "

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.undodir = os.getenv("HOME") .. "/.nvim/undodir"
vim.opt.undofile = true

-- https://github.com/ThePrimeagen/init.lua/blob/249f3b14cc517202c80c6babd0f9ec548351ec71/lua/theprimeagen/set.lua
-- https://neovim.io/doc/user/quickref.html#option-list
