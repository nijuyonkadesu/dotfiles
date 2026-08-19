local treesitter_group = vim.api.nvim_create_augroup('TreesitterConfig', { clear = true })

vim.api.nvim_create_autocmd('User', {
    pattern = 'TSUpdate',
    group = treesitter_group,
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
    group = treesitter_group,
    callback = function(ev)
        local buf = ev.buf
        local lang = vim.treesitter.language.get_lang(ev.match)
        if not lang then return end

        local parser_available = vim.treesitter.language.add(lang)
        if not parser_available then return end

        local query_ok, highlights = pcall(vim.treesitter.query.get, lang, 'highlights')
        if not query_ok or not highlights then return end

        local max_filesize = 100 * 1024
        local stats = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
        if stats and stats.size > max_filesize then
            vim.treesitter.stop(buf)
            vim.notify(
                'Tree-sitter highlighting disabled for files larger than 100 KiB',
                vim.log.levels.WARN,
                { title = 'Tree-sitter' }
            )
            return
        end
    -- since neovim 0.12.0? internally:
    -- local parser = assert(vim.treesitter.get_parser(bufnr, lang))
    -- vim.treesitter.highlighter.new(parser)
    -- highlighter.new() creates another highlighter, registers callbacks on the parser, and then overwrites:
    -- vim.treesitter.highlighter.active[bufnr] = new_highlighter
    if not vim.treesitter.highlighter.active[buf] then
            pcall(vim.treesitter.start, buf, lang)
        end
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

            require('nvim-treesitter').install({
                'c', 'lua', 'rust', 'cpp', 'go', 'javascript', 'typescript',
                'python', 'yaml', 'json', 'helm', 'gitcommit', 'templ',
                'markdown', 'markdown_inline', 'java', 'bash', 'vim', 'vimdoc',
                'query', 'toml', 'dockerfile', 'html', 'css', 'diff',
            })
        end
    },
    {
        'nvim-treesitter/nvim-treesitter-context',
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
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
