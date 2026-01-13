return {
    {
        'towolf/vim-helm',
        ft = { 'helm' },
        event = { "BufReadPre", "BufNewFile", "BufEnter" }
    },
    {
        'neovim/nvim-lspconfig',
        dependencies = {
            { 'williamboman/mason.nvim' },
            { 'williamboman/mason-lspconfig.nvim' },

            -- linters, formatters
            { 'nvim-lua/plenary.nvim' },
            { 'stevearc/conform.nvim' },

            -- Autocompletion
            { 'hrsh7th/nvim-cmp' },
            { 'hrsh7th/cmp-buffer' },
            { 'hrsh7th/cmp-path' },
            { 'hrsh7th/cmp-cmdline' },
            { 'hrsh7th/cmp-nvim-lsp' },
            { 'hrsh7th/cmp-nvim-lua' },
            { 'saadparwaiz1/cmp_luasnip' },

            -- Snippets
            { 'L3MON4D3/LuaSnip' },

            -- UI notification
            { 'j-hui/fidget.nvim' }
        },
        config = function()
            local cmp = require('cmp')
            local cmp_lsp = require("cmp_nvim_lsp")
            local capabilities = vim.tbl_deep_extend(
                "force",
                {},
                vim.lsp.protocol.make_client_capabilities(),
                cmp_lsp.default_capabilities())

            require("fidget").setup({})
            require("mason").setup()
            require("mason-lspconfig").setup({
                automatic_enable = true,
                automatic_installation = {
                    "black",
                    "prettier",
                },
                ensure_installed = {
                    "gopls",
                    "yamlls",
                    "marksman",
                    "basedpyright",
                    "jsonls",
                    "helm_ls",
                    "lua_ls",
                },
                handlers = {
                    function(server_name)
                        vim.lsp.config(server_name, {
                            capabilities = capabilities
                        })
                    end,
                },

                vim.lsp.config("lua_ls", {
                    capabilities = capabilities,
                    settings = {
                        Lua = {
                            diagnostics = {
                                globals = { "bit", "vim", "it", "describe", "before_each", "after_each" },
                            },
                            workspace = {
                                library = vim.api.nvim_get_runtime_file("", true),
                                checkThirdParty = false,
                            },
                            runtime = { version = "Lua 5.1" },
                            format = {
                                enable = true,
                                -- Put format options here
                                -- NOTE: the value should be STRING!!
                                defaultConfig = {
                                    indent_style = "space",
                                    indent_size = "2",
                                }
                            },
                        }
                    }
                }),

                vim.lsp.config("tailwindcss", {
                    capabilities = capabilities,
                    filetypes = { "html", "css", "scss", "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte", "heex" },
                }),

                vim.lsp.config("basedpyright", {
                    --local lspconfig = require('lspconfig')
                    --local util = require("lspconfig/util")
                    ---- https://www.reddit.com/r/neovim/comments/17bod01/how_do_i_select_a_python_enviroment_so_pyright/
                    ---- https://github.com/hahuang65/nvim-config/blob/38aca9f78b4e773d0452ecb953ccdbe9915ac3d9/lua/plugins/lsp.lua#L82
                    --on_init = function(client)
                    --    -- https://github.com/DetachHead/basedpyright/issues/482
                    --    client.server_capabilities.semanticTokensProvider = nil
                    --end,
                    --root_dir = function(fname)
                    --    local root = util.root_pattern("requirements.txt", "pyproject.toml", "setup.py", "app")(
                    --            fname)
                    --        or util.root_pattern(".git")(fname)
                    --        or util.path.dirname(fname)

                    --    local venv_dir = root .. 'venv'
                    --    if util.path.exists(venv_dir) then
                    --        vim.g.python3_host_prog = venv_dir .. '/bin/python'
                    --    end

                    --    return root
                    --end,
                    capabilities = capabilities,
                    settings = {
                        basedpyright = {
                            analysis = {
                                -- https://github.com/DetachHead/basedpyright/issues/168
                                diagnosticMode = "openFilesOnly",
                                typeCheckingMode = "standard",
                                reportMissingSuperCall = false,
                                autoSearchPaths = true,
                                extraPaths = dofile(vim.fn.stdpath('config') .. "/after/extra-paths.lua"),
                            },
                        },
                    },
                }),

                vim.lsp.config("helm_ls", {
                    capabilities = capabilities,
                    settings = {
                        ['helm-ls'] = {
                            yamlls = {
                                path = "yaml-language-server",
                            }
                        }
                    }
                })

            })

            cmp.setup({
                snippet = {
                    expand = function(args)
                        require('luasnip').lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ['<C-p>'] = cmp.mapping.select_prev_item(),
                    ['<C-n>'] = cmp.mapping.select_next_item(),
                    ['<C-y>'] = cmp.mapping.confirm({ select = true }),
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['<CR>'] = cmp.mapping.confirm({
                        behavior = cmp.ConfirmBehavior.Replace,
                        select = true,
                    }),
                    ['<Tab>'] = nil, -- disable completion with tab, this helps with copilot setup
                    ['<S-Tab>'] = nil,

                }),
                sources = cmp.config.sources({
                    { name = "luasnip" },
                    { name = "nvim_lsp" },
                    { name = "friendly_snippets" },
                }, {
                    { name = "path" },
                    { name = "buffer", keyword_length = 3 },
                }),
            })

            vim.diagnostic.config({
                -- update_in_insert = true,
                float = {
                    focusable = false,
                    style = "minimal",
                    border = "rounded",
                    source = true,
                    header = "",
                    prefix = "",
                },
            })

            vim.filetype.add({
                extension = {
                    templ = 'templ',
                }
            })

            vim.diagnostic.config({
                virtual_text = true,
            })
        end
    }
}
