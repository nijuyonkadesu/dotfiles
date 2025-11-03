function ColorMyPencils(color)
    color = color or "rose-pine"
    vim.cmd.colorscheme(color)

    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })      -- 0 means Global, apply to all windows
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" }) -- apply to floating windows
    vim.cmd([[hi Search guifg=#191724 guibg=#e0def4]])
end

return {
    {
        'rose-pine/neovim',
        name = 'rose-pine',

        config = function()
            require('rose-pine').setup({
                disable_background = true,
                -- styles = {
                --     italic = false,
                -- },
            })

            ColorMyPencils();
        end
    },
    {
        "ellisonleao/gruvbox.nvim",
        name = "gruvbox",
        config = function()
            require("gruvbox").setup({
                terminal_colors = true, -- add neovim terminal colors
                undercurl = true,
                underline = false,
                bold = true,
                -- italic = {
                --     strings = false,
                --     emphasis = false,
                --     comments = false,
                --     operators = false,
                --     folds = false,
                -- },
                strikethrough = true,
                invert_selection = false,
                invert_signs = false,
                invert_tabline = false,
                invert_intend_guides = false,
                inverse = true, -- invert background for search, diffs, statuslines and errors
                contrast = "",  -- can be "hard", "soft" or empty string
                palette_overrides = {},
                overrides = {},
                dim_inactive = false,
                transparent_mode = false,
            })
        end,
    },
    {
        "folke/tokyonight.nvim",
        config = function()
            require("tokyonight").setup({
                -- your configuration comes here
                -- or leave it empty to use the default settings
                style = "storm",        -- The theme comes in three styles, `storm`, `moon`, a darker variant `night` and `day`
                transparent = true,     -- Enable this to disable setting the background color
                terminal_colors = true, -- Configure the colors used when opening a `:terminal` in Neovim
                styles = {
                    -- Style to be applied to different syntax groups
                    -- Value is any valid attr-list value for `:help nvim_set_hl`
                    comments = { italic = false },
                    keywords = { italic = false },
                    -- Background styles. Can be "dark", "transparent" or "normal"
                    sidebars = "dark", -- style for sidebars, see below
                    floats = "dark",   -- style for floating windows
                },
            })
        end
    },
    {
        "tjdevries/colorbuddy.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            vim.cmd.colorscheme "gruvbuddy"
        end,
    },
    "tckmn/hotdog.vim", -- TROLL!??
    "craftzdog/solarized-osaka.nvim",
    "miikanissi/modus-themes.nvim",
    "rebelot/kanagawa.nvim",
    { "catppuccin/nvim", name = "catppuccin" },

    "dundargoc/fakedonalds.nvim",
    "eldritch-theme/eldritch.nvim",
    "jesseleite/nvim-noirbuddy",
    "gremble0/yellowbeans.nvim",
    "rockyzhang24/arctic.nvim",
    "Shatur/neovim-ayu",
    "RRethy/base16-nvim",
    "xero/miasma.nvim",
    "cocopon/iceberg.vim",
    "kepano/flexoki-neovim",
    "LuRsT/austere.vim",
    "ricardoraposo/gruvbox-minor.nvim",
    "NTBBloodbath/sweetie.nvim",
    "vim-scripts/MountainDew.vim",
    {
        "maxmx03/fluoromachine.nvim",
        config = function()
            local fm = require "fluoromachine"
            fm.setup { glow = true, theme = "fluoromachine" }
        end,
    },
}
