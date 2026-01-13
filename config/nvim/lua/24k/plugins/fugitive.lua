return {
    {
        "tpope/vim-fugitive",

        config = function()
            -- git status
            vim.keymap.set("n", "<leader>gs", vim.cmd.Git)
            vim.keymap.set("n", "<leader>gh", ":0Gclog<CR>", { desc = "Git file history" })
            vim.keymap.set("n", "<leader>gb", ":Git blame<CR>", { desc = "Git blame" })
            vim.keymap.set("n", "<leader>gl", ":Git log --oneline --graph<CR>", { desc = "Git log" })
            vim.keymap.set("n", "<leader>go", ":GBrowse!<CR>", { desc = "Yank github url" })

            vim.keymap.set("n", "<leader>gp", function()
                local branch = vim.fn.FugitiveHead()

                if branch == "" or branch == "HEAD" then
                    vim.notify("Could not determine current branch.", vim.log.levels.ERROR)
                    return
                end

                local cmd = ":G pull origin " .. branch .. " --rebase"
                vim.fn.feedkeys(cmd, "n")
            end, { desc = "Populate :G pull origin <branch> --rebase" })

            local qf_from_difftool = false
            local difftool_branch = ""

            local function is_difftool_qf()
                return qf_from_difftool and difftool_branch ~= ""
            end

            local function qf_navigate(direction)
                if is_difftool_qf() then
                    -- close all windows except the current one and quickfix
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        local buf = vim.api.nvim_win_get_buf(win)
                        local ft = vim.bo[buf].filetype

                        if win ~= vim.api.nvim_get_current_win() and ft ~= "qf" then
                            pcall(vim.api.nvim_win_close, win, false)
                        end
                    end
                end

                -- navigate
                local cmd = direction == "next" and "cn" or "cp"
                local ok = pcall(vim.cmd, cmd)

                if not ok then
                    return -- No more items in quickfix
                end

                vim.cmd("normal! zz")

                -- If from difftool, open the diff
                if is_difftool_qf() then
                    vim.cmd("Gvdiffsplit " .. difftool_branch)
                end
            end

            vim.keymap.set("n", "<M-J>", function() qf_navigate("next") end)
            vim.keymap.set("n", "<M-K>", function() qf_navigate("prev") end)

            vim.api.nvim_create_user_command("Gdifftoolc", function(opts)
                    local args = opts.args
                    if args == "" then
                        vim.notify("Please specify difftool arguments", vim.log.levels.ERROR)
                        return
                    end

                    local branch = ""
                    for word in args:gmatch("%S+") do
                        if not word:match("^%-") then
                            branch = word
                        end
                    end

                    if branch == "" then
                        vim.notify("Could not determine branch name", vim.log.levels.ERROR)
                        return
                    end

                    qf_from_difftool = true
                    difftool_branch = branch

                    vim.cmd("G difftool " .. args)

                    vim.api.nvim_create_autocmd("QuitPre", {
                        callback = function()
                            if vim.fn.getqflist({ winid = 0 }).winid ~= 0 then
                                qf_from_difftool = false
                                difftool_branch = ""
                            end
                        end,
                        once = true,
                    })
                end,
                {
                    nargs = "+",
                    complete = "customlist,fugitive#Complete",
                    desc = "difftool with auto-diff on navigation"
                })
        end
    },
    {
        "tpope/vim-rhubarb",
        dependencies = {
            "tpope/vim-fugitive",
        },
    }
}
