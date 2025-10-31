return {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' },

    setup = function()
        require("render-markdown").setup({
            code = {
                disable_background = { 'diff' },
            },
        })
    end
}
