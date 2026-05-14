return {
    "qvalentin/helm-ls.nvim",
    ft = "helm",
    -- lazy.nvim needs `opts` (or `config = true`) to call require("helm-ls").setup().
    -- Without this the plugin loads but never initializes its features
    -- (action-highlight, conceal-templates, indent-hints, %-matchparen).
    -- All three feature groups depend on the `helm` tree-sitter parser, which
    -- is installed via lua/24k/plugins/treesitter.lua.
    opts = {
        conceal_templates = {
            enabled = false
        },
        indent_hints = {
            enabled = false,
            only_for_current_line = true,
        },
        action_highlight = {
            enabled = true,
        },
    },
}
