local lsp = require("lsp-zero")
require("mason").setup()
require("mason-lspconfig").setup()

local lspconfig = require('lspconfig')
local util = require("lspconfig/util")
-- lspconfig.cmake.setup {
--     root_dir = util.root_pattern("build", "compile_commands.json", ".git")
-- }
--
lspconfig.pyright.setup({
  root_dir = function(fname)
    return util.root_pattern("requirements.txt", "pyproject.toml", "setup.py", "setup.cfg", "app")(fname)
      or util.root_pattern(".git")(fname)
      or util.path.dirname(fname)
  end,
})

lspconfig.jsonls.setup {}
lspconfig.java_language_server.setup {}
lspconfig.kotlin_language_server.setup {}
lspconfig.helm_ls.setup {
    settings = {
        ['helm-ls'] = {
            yamlls = {
                path = "yaml-language-server",
            }
        }
    }
}
lspconfig.yamlls.setup {}
lspconfig.gopls.setup {}
-- lspconfig.mypy.setup { settings = { server = "pyright" } }
lspconfig.marksman.setup {}

-- lspconfig.prettier.setup {}
-- use null ls / nvim lint

lsp.preset("recommended")

-- lsp.ensure_installed({
-- 'clangd',
-- })

-- Fix Undefined global 'vim'

require("luasnip.loaders.from_vscode").lazy_load()
local cmp = require('cmp')
-- TODO: https://github.com/neovim/nvim-lspconfig/wiki/Autocompletion
-- local capabilities = require("cmp_nvim_lsp").default_capabilities()
local cmp_action = require("lsp-zero").cmp_action()
cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end, 
  }, 
  mapping = cmp.mapping.preset.insert({
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-y>'] = cmp.mapping.confirm({ select = true }),
    ["<C-Space>"] = cmp.mapping.complete(),
    ['<C-f>'] = cmp_action.luasnip_jump_forward(),
    ['<C-b>'] = cmp_action.luasnip_jump_backward(),
    ['<CR>'] = cmp.mapping.confirm({
          behavior = cmp.ConfirmBehavior.Replace,
          select = true,
        }),
    ['<Tab>'] = nil,
    ['<S-Tab>'] = nil,

  }),
    sources = {
    { name = "luasnip" }, 
    { name = "path" },
    { name = "nvim_lsp" },
    { name = "buffer", keyword_length = 3 }, 
    { name = "friendly_snippets" } 
  },
})
-- disable completion with tab
-- this helps with copilot setup

lsp.set_preferences({
    suggest_lsp_servers = false,
    sign_icons = {
        error = 'E',
        warn = 'W',
        hint = 'H',
        info = 'I'
    }
})

lsp.on_attach(function(client, bufnr)
  local opts = {buffer = bufnr, remap = false}

  if client.name == "eslint" then
      vim.cmd.LspStop('eslint')
      return
  end

  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
  vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, opts)
  vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, opts)
  vim.keymap.set("n", "[d", vim.diagnostic.goto_next, opts)
  vim.keymap.set("n", "]d", vim.diagnostic.goto_prev, opts)
  vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, opts)
  vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references, opts)
  vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, opts)
  vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)
end)

lsp.setup()

vim.diagnostic.config({
    virtual_text = true,
})

