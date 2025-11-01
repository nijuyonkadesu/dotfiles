return {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    build = "make install_jsregexp",
    dependencies = { "rafamadriz/friendly-snippets" },

    config = function()
        require("luasnip.loaders.from_vscode").lazy_load()
        local ls = require("luasnip")
        ls.filetype_extend("javascript", { "jsdoc" })

        -- taken from lsp-zero! original method: cmp_action.luasnip_jump_forward()
        vim.keymap.set({ "i", "s" }, "<C-f>", function()
            if ls.locally_jumpable(1) then
                ls.jump(1)
            end
        end, { silent = true })

        vim.keymap.set({ "i", "s" }, "<C-b>", function()
            if ls.locally_jumpable(-1) then
                ls.jump(-1)
            end
        end, { silent = true })
    end,
}
