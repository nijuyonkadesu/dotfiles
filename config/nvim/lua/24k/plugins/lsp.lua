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
            -----------------------------------------------------------------
            -- mason-lspconfig: install servers + auto-enable them.
            -- With automatic_enable=true it calls vim.lsp.enable() for each
            -- server in ensure_installed; the handlers/automatic_installation
            -- options from v1.x are no longer used here.
            -----------------------------------------------------------------
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
                    "jdtls",
                },
            })

            -----------------------------------------------------------------
            -- LSP server configuration (nvim 0.12 native API)
            --   nvim-lspconfig ships defaults at lsp/<name>.lua; vim.lsp.config
            --   merges per-server overrides on top of those. mason-lspconfig's
            --   automatic_enable then calls vim.lsp.enable() for ensure_installed.
            -----------------------------------------------------------------

            -- Global default for every server
            vim.lsp.config("*", {
                capabilities = capabilities,
            })

            vim.lsp.config("lua_ls", {
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
                            },
                        },
                    },
                },
            })

            vim.lsp.config("tailwindcss", {
                capabilities = capabilities,
                filetypes = { "html", "css", "scss", "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte", "heex" },
            })

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
            })

            -- yaml-language-server.
            --   - `kubernetes` is a special schema key built into yamlls (its own
            --     bundled k8s schema). Mapping it to globs is what gives you
            --     `rep<C-Space>` -> `replicas` on plain k8s manifests.
            --   - schemaStore.enable=true makes yamlls fetch the schemastore.org
            --     catalog itself for gh-actions / package.json / compose / etc.
            --     (no SchemaStore.nvim needed).
            --   - Filetypes: helm-ls.nvim ftdetects values.yaml as `yaml.helm-values`,
            --     so we extend yamlls's filetype list to attach there.
            --     Templates under chart/templates/* are filetype `helm` and remain
            --     handled exclusively by helm_ls (yamlls does NOT attach there).
            vim.lsp.config("yamlls", {
                filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab", "yaml.helm-values" },
                settings = {
                    yaml = {
                        keyOrdering = false,
                        validate = true,
                        completion = true,
                        hover = true,
                        schemaStore = {
                            enable = true,
                            url = "https://www.schemastore.org/api/json/catalog.json",
                        },
                        -- schemas = {
                        --     -- Built-in k8s schema in yamlls; broad globs cover
                        --     -- common manifest locations and *-deployment.yaml etc.
                        --     kubernetes = {
                        --         "**/k8s/**/*.{yaml,yml}",
                        --         "**/kubernetes/**/*.{yaml,yml}",
                        --         "**/manifests/**/*.{yaml,yml}",
                        --         "**/deploy/**/*.{yaml,yml}",
                        --         "deployment.yaml",
                        --         "service.yaml",
                        --         "ingress.yaml",
                        --         "configmap.yaml",
                        --         "*-deployment.{yaml,yml}",
                        --         "*-service.{yaml,yml}",
                        --         "*-ingress.{yaml,yml}",
                        --         "*-configmap.{yaml,yml}",
                        --     },
                        -- },
                    },
                },
            })

            vim.lsp.config("jsonls", {
                settings = {
                    json = {
                        validate = { enable = true },
                    },
                },
            })

            -- helm-ls: pass absolute path of yaml-language-server (avoids PATH issues
            -- in the helm-ls subprocess) and bump diagnostics limit so duplicate-key
            -- errors aren't hidden.
            --
            -- showDiagnosticsDirectly=true is REQUIRED here:
            --   helm-ls strips Go-template tags ({{ ... }}) before forwarding to
            --   yamlls (see internal/adapter/yamlls/document_sync_template.go:42,
            --   67, 94 -- `lsplocal.TrimTemplate`), so yamlls sees clean YAML and
            --   won't produce template-related false positives.
            --
            --   With this flag false (the helm-ls default), the diagnostics cache
            --   (internal/lsp/document/diagnostics_cache.go:44-48) suppresses
            --   yamlls updates after the first ~3 events unless the error COUNT
            --   decreases. That is why first duplicate-key shows up, but every
            --   subsequent new error is silently dropped.
            --
            -- Broaden the kubernetes schema glob: the default `templates/**` is
            -- anchored relative to chart root and fails for nested chart layouts
            -- (e.g. charts/<service>/templates/...). `**/templates/**/*.{yaml,yml}`
            -- matches templates inside any chart depth.
            vim.lsp.config("helm_ls", {
                settings = {
                    ['helm-ls'] = {
                        yamlls = {
                            enabled = true,
                            -- enabledForFilesGlob = "*.{yaml,yml}",
                            -- diagnosticsLimit = 100,
                            showDiagnosticsDirectly = true,
                            path = vim.fn.exepath("yaml-language-server"),
                            -- initTimeoutSeconds = 5,
                            -- config = {
                            --     schemas = {
                            --         kubernetes = "**/templates/**/*.{yaml,yml}",
                            --     },
                            --     completion = true,
                            --     hover = true,
                            --     -- schemaStore = {
                            --     --     enable = true,
                            --     --     url = "https://www.schemastore.org/api/json/catalog.json",
                            --     -- },
                            -- },
                        },
                    },
                },
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
                virtual_text = true,
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
                },
            })
        end,
    },
}
