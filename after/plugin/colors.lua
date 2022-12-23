function ColorMyPencils(color)
    color = color or "rose-pine"
    vim.cmd.colorscheme(color)
    
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" }) -- 0 means Global, apply to all windows
    vim.api.nvim_set_hl(0, "NormalFlag", { bg = "none" }) -- apply to floating windows
end

ColorMyPencils()
