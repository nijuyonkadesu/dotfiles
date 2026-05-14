vim.api.nvim_create_autocmd('User', {
    pattern = 'TSUpdate',
    callback = function()
        require('nvim-treesitter.parsers').templ = {
            install_info = {
                url = "https://github.com/vrischmann/tree-sitter-templ.git",
                branch = "master",
                queries = 'queries/templ',
            },
        }
    end,
})

-- :h treesitter-quickstart and the nvim-treesitter main README (https://github.com/nvim-treesitter/nvim-treesitter/tree/main#quickstart) both spell this out:
-- > The main branch only handles installing/updating parsers and queries. To enable highlighting, indents, or folds for a buffer, you have to call vim.treesitter.start() yourself (typically from a FileType autocmd).
-- sike... thanks, claude for fixing helm lsp & broken gitcommit colors
vim.api.nvim_create_autocmd('FileType', {
    callback = function()
        -- Files larger than 100 KB still skip treesitter for perf.
        local max_filesize = 100 * 1024 -- 100KB
        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(0))
        if ok and stats and stats.size > max_filesize then
            vim.notify(
                "File larger than 100KB treesitter disabled for performance",
                vim.log.levels.WARN,
                { title = "Treesitter" }
            )
            return
        end
        -- not specifying pattern fires treesitter for all buffers. ig this is how it was prior to 0.12.0 neovim
        -- pcall silently eats error message from treesitter whn no parser are installed
        pcall(vim.treesitter.start)
    end,
})

return {
    {
        'nvim-treesitter/nvim-treesitter',
        branch = 'main',
        build = ':TSUpdate',
        lazy = false,

        config = function()
            require('nvim-treesitter').setup {
                install_dir = vim.fn.stdpath('data') .. '/site'
            }

            -- Parsers to keep installed/updated. The auto-attach autocmd above
            -- will pick up anything in this list (and anything you `:TSInstall`
            -- ad-hoc) without further config changes.
            require('nvim-treesitter').install({
                'c', 'lua', 'rust', 'cpp', 'go', 'javascript', 'typescript',
                'python', 'yaml', 'json', 'helm', 'gitcommit', 'templ',
                'markdown', 'markdown_inline', 'java', 'bash', 'vim', 'vimdoc',
                'query', 'toml', 'dockerfile', 'html', 'css',
            })
        end
    },
    {
        'nvim-treesitter/nvim-treesitter-context',
        after = 'nvim-treesitter',
        config = function()
            require 'treesitter-context'.setup {
                enable = true,            -- Enable this plugin (Can be enabled/disabled later via commands)
                multiwindow = false,      -- Enable multiwindow support.
                max_lines = 0,            -- How many lines the window should span. Values <= 0 mean no limit.
                min_window_height = 0,    -- Minimum editor window height to enable context. Values <= 0 mean no limit.
                line_numbers = true,
                multiline_threshold = 20, -- Maximum number of lines to show for a single context
                trim_scope = 'outer',     -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
                mode = 'cursor',          -- Line used to calculate context. Choices: 'cursor', 'topline'

                -- Separator between context and content. Should be a single character string, like '-'.
                -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
                separator = nil,
                zindex = 20,     -- The Z-index of the context window
                on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
            }
        end
    }
}
