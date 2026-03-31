return {
    'nvim-telescope/telescope.nvim',
    tag = 'v0.2.2',
    dependencies = {
        { 'nvim-lua/plenary.nvim' }
    },
    config = function()
        local actions = require('telescope.actions')
        require('telescope').setup {
            defaults = {
                file_ignore_patterns = {
                    "node_modules",
                    "venv",
                },
                -- in insert mode, preserve the default behaviour (complete tag), in normal mode, send to location list, for now I can work with this compromise
                mappings = {
                    n = {
                        ["<C-L>"] = actions.send_to_loclist + actions.open_loclist,
                    },
                },
            }
        }
        require('telescope').load_extension('fzf')
        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
        vim.keymap.set('n', '<C-p>', builtin.git_files, {})
        vim.keymap.set('n', '<leader>ws', builtin.lsp_workspace_symbols, {})
        vim.keymap.set('n', '<leader>ds', builtin.lsp_document_symbols, {})
        vim.keymap.set('n', '<M-e>', builtin.resume, {})
        vim.keymap.set('n', '<leader>ps', function()
            builtin.grep_string({ search = vim.fn.input("Grep > ") });
        end)
        vim.keymap.set('n', '<leader>pws', function()
            local word = vim.fn.expand("<cword>")
            builtin.grep_string({ search = word })
        end)
        vim.keymap.set('n', '<leader>pWs', function()
            local word = vim.fn.expand("<cWORD>")
            builtin.grep_string({ search = word })
        end)
        vim.keymap.set('n', '<leader>vh', builtin.help_tags, {})
        -- pf > all project file search
        -- Ctrl + p > only git files)
    end
}
