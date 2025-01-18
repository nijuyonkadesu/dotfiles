local lsp = require("lsp-zero")
local cmp = require('cmp')
local cmp_lsp = require("cmp_nvim_lsp")
local capabilities = vim.tbl_deep_extend(
            "force",
            {},
            vim.lsp.protocol.make_client_capabilities(),
            cmp_lsp.default_capabilities())
require("mason").setup()
require("mason-lspconfig").setup({
    ensure_installed = {
        "gopls",
        "yamlls",
        "marksman",
        "pyright",
        "black",
        "pyright",
        "jsonls",
        "helm_ls",
    },
    function(server_name) -- default handler (optional)
        require("lspconfig")[server_name].setup {
            capabilities = capabilities
        }
    end,
})

local lspconfig = require('lspconfig')
local util = require("lspconfig/util")
-- lspconfig.cmake.setup {
--     root_dir = util.root_pattern("build", "compile_commands.json", ".git")
-- }
--
-- https://www.reddit.com/r/neovim/comments/17bod01/how_do_i_select_a_python_enviroment_so_pyright/
-- https://github.com/hahuang65/nvim-config/blob/38aca9f78b4e773d0452ecb953ccdbe9915ac3d9/lua/plugins/lsp.lua#L82
lspconfig.pyright.setup({
  root_dir = function(fname)
    local root = util.root_pattern("requirements.txt", "pyproject.toml", "setup.py", "app")(fname)
        or util.root_pattern(".git")(fname)
        or util.path.dirname(fname)

    local venv_dir = util.path.join(root, 'venv')
    if util.path.exists(venv_dir) then
      vim.g.python3_host_prog = venv_dir .. '/bin/python'
    end

    return root
  end,
  settings = {
    python = {
      pythonPath = vim.g.python3_host_prog,
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "workspace",
        extraPaths = {
          "/Users/sriramv/redacted/airbyte/airbyte-cdk/python"
        },
      },
    }
  },
})

lspconfig.helm_ls.setup {
    settings = {
        ['helm-ls'] = {
            yamlls = {
                path = "yaml-language-server",
            }
        }
    }
}
lspconfig.lua_ls.setup {
    capabilities = capabilities,
    settings = {
        Lua = {
            runtime = { version = "Lua 5.1" },
            diagnostics = {
                globals = { "bit", "vim", "it", "describe", "before_each", "after_each" },
            }
        }
    }
}

require("luasnip.loaders.from_vscode").lazy_load()
local cmp_action = lsp.cmp_action()
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

vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = 'E',
      [vim.diagnostic.severity.WARN] = 'W',
      [vim.diagnostic.severity.HINT] = 'H',
      [vim.diagnostic.severity.INFO] = 'I',
    },
  },
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

