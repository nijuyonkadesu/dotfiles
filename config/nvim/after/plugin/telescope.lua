require('telescope').setup {
    defaults = {
        file_ignore_patterns = {
            "node_modules",
            "venv",
        }
    }
}
local builtin = require('telescope.builtin')
local cwd = vim.fn.getcwd(-1)
vim.keymap.set('n', '<leader>pf', function() builtin.find_files({ cwd = cwd }) end)
vim.keymap.set('n', '<C-p>', function() builtin.git_files({ cwd = cwd }) end)
vim.keymap.set('n', '<leader>ps', function()
    builtin.grep_string({ search = vim.fn.input("Grep > "), cwd = cwd });
end)
vim.keymap.set('n', '<leader>pws', function()
    local word = vim.fn.expand("<cword>")
    builtin.grep_string({ search = word, cwd = cwd })
end)
vim.keymap.set('n', '<leader>pWs', function()
    local word = vim.fn.expand("<cWORD>")
    builtin.grep_string({ search = word, cwd = cwd })
end)
vim.keymap.set('n', '<leader>vh', builtin.help_tags, {})
-- pf > all project file search
-- Ctrl + p > only git files)
