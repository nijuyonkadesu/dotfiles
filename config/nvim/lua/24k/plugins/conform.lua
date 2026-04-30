return {
    "stevearc/conform.nvim",
    opts = {},

    config = function()
        vim.keymap.set("n", "<leader>f", function()
            local conform = require("conform")
            conform.format({
                lsp_fallback = true,
                async = true,
                timeout_ms = 500,
            })
        end)

        require("conform").setup({
                formatters_by_ft = {
                    lua = { "stylua" },
                    python = { "black" },
                    rust = { "rustfmt", lsp_format = "fallback" },
                    javascript = { "prettierd", "prettier", stop_after_first = true },
                    markdown = { "prettierd", "prettier", stop_after_first = true },
                    java = { "google-java-format" },
                },
            formatters = {
                ["clang-format"] = {
                    prepend_args = { "-style=file", "-fallback-style=LLVM" },
                },
            },
        })
    end,
}
