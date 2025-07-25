require("nvim-treesitter.configs").setup {
    -- A list of parser names, or "all"
    ensure_installed = { "c", "lua", "rust", "cpp", "go", "javascript", "typescript", "python", "yaml" },

    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,

    -- Automatically install missing parsers when entering buffer
    -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
    auto_install = true,
    indent = { enable = false },
    highlight = {
        -- `false` will disable the whole extension
        enable = true,
        disable = function(lang, buf)
            if lang == "html" then
                print("disabled")
                return true
            end

            local max_filesize = 100 * 1024 -- 100 KB
            local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then
                vim.notify(
                    "File larger than 100KB treesitter disabled for performance",
                    vim.log.levels.WARN,
                    { title = "Treesitter" }
                )
                return true
            end
        end,
        additional_vim_regex_highlighting = false,
    },
}
