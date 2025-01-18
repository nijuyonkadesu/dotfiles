return {
    {
        'nvim-telescope/telescope.nvim', tag = '0.1.8',
        dependencies = { 
            { 'nvim-lua/plenary.nvim' } 
        }
    },
    {
        'rose-pine/neovim',
        name = 'rose-pine',
        config = function()
            vim.cmd('colorscheme rose-pine')
        end
    },
    { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate' },
    { 'ThePrimeagen/harpoon' },
    { 'mbbill/undotree' },
    { 'tpope/vim-fugitive' },
    {
        'towolf/vim-helm',
        ft = { 'helm' }, 
        event = { "BufReadPre", "BufNewFile", "BufEnter" }
    },
    {
        'VonHeikemen/lsp-zero.nvim',
        dependencies = {
            -- LSP Support
            {'neovim/nvim-lspconfig'},
            {'williamboman/mason.nvim'},
            {'williamboman/mason-lspconfig.nvim'},

            -- linters, formatters
            {'nvim-lua/plenary.nvim'},
            {'jose-elias-alvarez/null-ls.nvim'},

            -- Autocompletion
            {'hrsh7th/nvim-cmp'},
            {'hrsh7th/cmp-buffer'},
            {'hrsh7th/cmp-path'},
            {'saadparwaiz1/cmp_luasnip'},
            {'hrsh7th/cmp-nvim-lsp'},
            {'hrsh7th/cmp-nvim-lua'},

            -- Snippets
            {
                'L3MON4D3/LuaSnip',
                build = "make install_jsregexp",
                dependencies = { "rafamadriz/friendly-snippets" },
            },
            {'rafamadriz/friendly-snippets'},
        }
    }
}
