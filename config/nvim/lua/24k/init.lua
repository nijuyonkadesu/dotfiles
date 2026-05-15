require("24k.remap")
require("24k.set")
require("24k.lazy")

-- automatically detect filetypes like log / conf etc
vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
    callback = function(ev)
        vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(ev.buf) then return end
            if vim.bo[ev.buf].buftype ~= '' then return end
            if vim.bo[ev.buf].filetype ~= '' then return end
            local name = vim.api.nvim_buf_get_name(ev.buf)
            local ext = vim.fn.fnamemodify(name, ':e')
            if ext == '' then return end
            vim.bo[ev.buf].filetype = ext:lower()
        end)
    end,
})

local augroup = vim.api.nvim_create_augroup
local LspGroup = augroup('LspGroup', {})
local autocmd = vim.api.nvim_create_autocmd

-- autocmd('BufEnter', {
--     group = LspGroup,
--     callback = function()
--         if vim.bo.filetype == "json" then
--             pcall(vim.cmd.colorscheme, "tokyonight-night")
--         else
--             pcall(vim.cmd.colorscheme, "rose-pine")
--         end
--     end
-- })

autocmd('LspAttach', {
    group = LspGroup,
    callback = function(e)
        local opts = { buffer = e.buf }
        vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
        vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
        vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
        vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
        vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
        vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, opts)
        vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
        vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
        vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
        vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
    end
})
