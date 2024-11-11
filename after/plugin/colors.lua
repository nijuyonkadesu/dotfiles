function ColorMyPencils(color)
    color = color or "rose-pine"
    vim.cmd.colorscheme(color)
    
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" }) -- 0 means Global, apply to all windows
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" }) -- apply to floating windows
    vim.cmd([[hi Search guifg=#191724 guibg=#e0def4]])
end

ColorMyPencils()
