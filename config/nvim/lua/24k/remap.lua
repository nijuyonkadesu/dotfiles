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
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

vim.keymap.set("n", "Q", "<nop>")

-- regex sub
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- windo diff
vim.keymap.set("n", "<leader>wt", "[[:windo difft<CR>]]")
vim.keymap.set("n", "<leader>wo", "[[:windo diffo<CR>]]")

-- lsp format
-- vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)
vim.keymap.set("n", "<leader>f", function()
    local conform = require("conform")
    conform.format({
        lsp_fallback = true,
        async = true,
        timeout_ms = 500,
    })
end)

-- quickfix navigation ref: https://www.youtube.com/watch?v=wOdL2T4hANk
-- macos_option_as_alt right (in kitty conf)
-- :cdo s/match/sub/gc
vim.keymap.set("n", "<M-j>", "<cmd>cn<CR>zz")
vim.keymap.set("n", "<M-k>", "<cmd>cp<CR>zz")

-- go err
vim.keymap.set(
    "n",
    "<leader>ee",
    "oif err != nil {<CR>}<Esc>Oreturn err<Esc>"
)

-- cleans up incorrect json (python dict)
vim.keymap.set("v", "<leader>j", function()
    local start_pos = vim.fn.getpos('v')
    local end_pos = vim.fn.getpos('.')

    local start_line = start_pos[2] - 1
    local end_line = end_pos[2]

    local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line, false)
    local content = table.concat(lines, "\n")

    local tmp_file = os.tmpname()
    local f = io.open(tmp_file, "w")
    f:write(content)
    f:close()

    local python_cmd = string.format([[
python3 -c "
import json, ast

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

    local code = os.execute(python_cmd)

    if code == 0 then
        f = io.open(tmp_file, "r")
        local content = f:read("*all")
        f:close()
        os.remove(tmp_file)

        local new_lines = vim.split(content, "\n", { plain = true })
        vim.api.nvim_buf_set_lines(0, start_line, end_line, false, new_lines)
    else
        vim.notify("skill issue.", vim.log.levels.ERROR)
    end
end, { desc = "Format JSON/python dict in visual selection" })

vim.keymap.set("v", "<leader>q", "!jq ")

-- replace new line with actual newline character
vim.keymap.set("v", "<leader>nl", '%s/\\n/')

-- toggle wrap text
vim.keymap.set("n", "<leader>l", function()
  if vim.wo.wrap then
    vim.wo.wrap = false
    vim.wo.linebreak = false
  else
    vim.wo.wrap = true
    vim.wo.linebreak = true
  end
end, { desc = "toggle wrap+linebreak" })
