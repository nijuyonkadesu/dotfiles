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
            -- { 'WhoIsSethDaniel/mason-tool-installer.nvim' },

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
            { 'rafamadriz/friendly-snippets' },
            {
                'L3MON4D3/LuaSnip',
                build = "make install_jsregexp",
                dependencies = { "rafamadriz/friendly-snippets" },
            },
            -- UI notification
            { 'j-hui/fidget.nvim' }
        },
        config = function()
            require("conform").setup({
                formatters_by_ft = {
                    lua = { "stylua" },
                    python = { "black" },
                    rust = { "rustfmt", lsp_format = "fallback" },
                    javascript = { "prettierd", "prettier", stop_after_first = true },
                    markdown = { "prettierd", "prettier", stop_after_first = true },
                },
            })

            local cmp = require('cmp')
            local cmp_lsp = require("cmp_nvim_lsp")
            local capabilities = vim.tbl_deep_extend(
                "force",
                {},
                vim.lsp.protocol.make_client_capabilities(),
                cmp_lsp.default_capabilities())

            require("fidget").setup({})
            require("mason").setup()
            -- require("mason-tool-installer").setup({
            --     ensure_installed = {
            --         "black",
            --         "prettier",
            --     },
            -- })
            require("mason-lspconfig").setup({
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
                        require("lspconfig")[server_name].setup {
                            capabilities = capabilities
                        }
                    end,

                    ["lua_ls"] = function()
                        local lspconfig = require("lspconfig")
                        lspconfig.lua_ls.setup {
                            capabilities = capabilities,
                            settings = {
                                Lua = {
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
                        }
                    end,

                    ["tailwindcss"] = function()
                        local lspconfig = require("lspconfig")
                        lspconfig.tailwindcss.setup({
                            capabilities = capabilities,
                            filetypes = { "html", "css", "scss", "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte", "heex" },
                        })
                    end,

                    ["basedpyright"] = function()
                        local lspconfig = require('lspconfig')
                        local util = require("lspconfig/util")
                        -- https://www.reddit.com/r/neovim/comments/17bod01/how_do_i_select_a_python_enviroment_so_pyright/
                        -- https://github.com/hahuang65/nvim-config/blob/38aca9f78b4e773d0452ecb953ccdbe9915ac3d9/lua/plugins/lsp.lua#L82
                        lspconfig.basedpyright.setup({
                            on_init = function(client)
                                -- https://github.com/DetachHead/basedpyright/issues/482
                                client.server_capabilities.semanticTokensProvider = nil
                            end,
                            root_dir = function(fname)
                                local root = util.root_pattern("requirements.txt", "pyproject.toml", "setup.py", "app")(
                                        fname)
                                    or util.root_pattern(".git")(fname)
                                    or util.path.dirname(fname)

                                local venv_dir = root .. 'venv'
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
                                        extraPaths = dofile(vim.fn.stdpath('config') .. "/after/extra-paths.lua"),
                                    },
                                },
                                basedpyright = {
                                    -- https://github.com/DetachHead/basedpyright/issues/168
                                    typeCheckingMode = "standard",
                                    reportMissingSuperCall = false,
                                },
                            },
                        })
                    end,

                    ["helm_ls"] = function()
                        local lspconfig = require('lspconfig')
                        lspconfig.helm_ls.setup {
                            settings = {
                                ['helm-ls'] = {
                                    yamlls = {
                                        path = "yaml-language-server",
                                    }
                                }
                            }
                        }
                    end,
                }
            })

            local cmp_select = { behavior = cmp.SelectBehavior.Select }
            -- local cmp_action = lsp.cmp_action()
            cmp.setup({
                snippet = {
                    expand = function(args)
                        require('luasnip').lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
                    ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
                    ['<C-y>'] = cmp.mapping.confirm({ select = true }),
                    ['<C-Space>'] = cmp.mapping.complete(),
                    -- ['<C-f>'] = cmp_action.luasnip_jump_forward(),
                    -- ['<C-b>'] = cmp_action.luasnip_jump_backward(),
                    ['<CR>'] = cmp.mapping.confirm({
                        behavior = cmp.ConfirmBehavior.Replace,
                        select = true,
                    }),
                    ['<Tab>'] = nil, -- disable completion with tab, this helps with copilot setup
                    ['<S-Tab>'] = nil,

                }),
                sources = {
                    { name = "luasnip" },
                    { name = "path" },
                    { name = "nvim_lsp" },
                    { name = "buffer",           keyword_length = 3 },
                    { name = "friendly_snippets" }
                },
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
