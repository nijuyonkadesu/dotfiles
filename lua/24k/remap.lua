vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- move highlighted text
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Join multiple lines while curser unmoved
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Search terms are focused in the middle
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- void buffer tricks
vim.keymap.set("x", "<leader>p", [["_dP]])

-- System clipboard
vim.keymap.set({"n", "v"}, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

vim.keymap.set("n", "Q", "<nop>")

-- regex sub
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- lsp format
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)

-- go err
vim.keymap.set(
    "n",
    "<leader>ee",
    "oif err != nil {<CR>}<Esc>Oreturn err<Esc>"
)

-- cleans up incorrect json (python dict) 
vim.keymap.set("n", "<leader>j", function()
    vim.cmd([[silent! %s/'/"/gi]])
    vim.cmd([[silent! %s/None/null/gi]])
    vim.cmd([[silent! %s/True/true/gi]])
    vim.cmd([[silent! %s/False/false/gi]])
end)
vim.keymap.set("v", "<leader>j", "!jq ")

