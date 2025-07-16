return {
    {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.8',
        dependencies = {
            { 'nvim-lua/plenary.nvim' }
        }
    },
    { 'rose-pine/neovim',                name = 'rose-pine' },
    { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate', lazy = false },
    { 'ThePrimeagen/harpoon' },
    { 'mbbill/undotree' },
    { 'github/copilot.vim' },
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
            {
                'neovim/nvim-lspconfig',
                dependencies = {
                    "folke/lazydev.nvim",
                    ft = "lua",
                    opts = {
                        library = {
                            -- Load luvit types when the `vim.uv` word is found
                            { path = "luvit-meta/library", words = { "vim%.uv" } },
                        },
                    },
                }
            },
            { 'williamboman/mason.nvim' },
            { 'williamboman/mason-lspconfig.nvim' },
            { 'WhoIsSethDaniel/mason-tool-installer.nvim' },

            -- linters, formatters
            { 'nvim-lua/plenary.nvim' },
            { 'stevearc/conform.nvim',                    opts = {}, },

            -- Autocompletion
            { 'hrsh7th/nvim-cmp' },
            { 'hrsh7th/cmp-buffer' },
            { 'hrsh7th/cmp-path' },
            { 'saadparwaiz1/cmp_luasnip' },
            { 'hrsh7th/cmp-nvim-lsp' },
            { 'hrsh7th/cmp-nvim-lua' },

            -- Snippets
            { 'rafamadriz/friendly-snippets' },
            {
                'L3MON4D3/LuaSnip',
                build = "make install_jsregexp",
                dependencies = { "rafamadriz/friendly-snippets" },
            },
            {
                'MeanderingProgrammer/render-markdown.nvim',
                dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' },
            }
        }
    }
}
