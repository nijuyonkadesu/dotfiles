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
-- vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)
vim.keymap.set("n", "<leader>f", function()
  local conform = require("conform")
  conform.format({
    lsp_fallback = true,
    async = false,
    timeout_ms = 500,
  })
end)

-- go err
vim.keymap.set(
    "n",
    "<leader>ee",
    "oif err != nil {<CR>}<Esc>Oreturn err<Esc>"
)

-- cleans up incorrect json (python dict) 
vim.keymap.set("v", "<leader>j", function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local content = table.concat(lines, "\n")

    local tmp_file = os.tmpname()
    local f = io.open(tmp_file, "w")
    f:write(content)
    f:close()

    local python_cmd = string.format([[
python3 -c "
import json
import ast

with open('%s', 'r') as f:
    content = f.read()

try:
    data = json.loads(content)
except json.JSONDecodeError:
    data = ast.literal_eval(content)

with open('%s', 'w') as f:
    json.dump(data, f)
"
    ]], tmp_file, tmp_file)

    os.execute(python_cmd)

    f = io.open(tmp_file, "r")
    content = f:read("*all")
    f:close()

    os.remove(tmp_file)

    vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(content, "\n"))
end)
vim.keymap.set("v", "<leader>q", "!jq ")

-- replace new line with actual newline character
vim.keymap.set("v", "<leader>nl", '%s/\\n/')

