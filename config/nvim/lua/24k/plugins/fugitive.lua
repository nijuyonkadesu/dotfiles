return {
    'tpope/vim-fugitive',

    config = function()
        -- git status
        vim.keymap.set("n", "<leader>gs", vim.cmd.Git);
    end
}
