-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function()
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'
  -- use 'folke/tokyonight.nvim'
  use 'ThePrimeagen/vim-be-good'

  use {
      'nvim-telescope/telescope.nvim', tag = '0.1.4',
      -- or, branch = '0.1.x',
      requires = { {'nvim-lua/plenary.nvim'} }
  }
  use({
      'rose-pine/neovim',
      as = 'rose-pine',
      config = function()
          vim.cmd('colorscheme rose-pine')
      end
  })
  use ('nvim-treesitter/nvim-treesitter', {run = ':TSUpdate'})
  use ('ThePrimeagen/harpoon')
  use ('mbbill/undotree')
  use ('tpope/vim-fugitive')
  use {
    'towolf/vim-helm',
    ft = { 'helm' }, 
    event = { "BufReadPre", "BufNewFile", "BufEnter" }
  }

  -- LSP zero
  use {
      'VonHeikemen/lsp-zero.nvim',
      requires = {
          -- LSP Support
          {'neovim/nvim-lspconfig'},
          {'williamboman/mason.nvim'},
          {'williamboman/mason-lspconfig.nvim'},

          -- Autocompletion
          {'hrsh7th/nvim-cmp'},
          {'hrsh7th/cmp-buffer'},
          {'hrsh7th/cmp-path'},
          {'saadparwaiz1/cmp_luasnip'},
          {'hrsh7th/cmp-nvim-lsp'},
          {'hrsh7th/cmp-nvim-lua'},

          -- Snippets
          {'L3MON4D3/LuaSnip'},
          {'rafamadriz/friendly-snippets'},
      }
  }
 end)
