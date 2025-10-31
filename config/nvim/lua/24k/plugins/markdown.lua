return {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' },

    config = function()
        require("render-markdown").setup({
            code = {
                disable_background = true,
                language_icon = true,
            },
        })
    end
}
