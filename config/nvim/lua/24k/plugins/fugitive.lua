return {
    {
        "tpope/vim-fugitive",

        config = function()
            -- git status
            vim.keymap.set("n", "<leader>gs", vim.cmd.Git)
            vim.keymap.set("n", "<leader>gh", ":0Gclog<CR>", { desc = "Git file history" })
            vim.keymap.set("n", "<leader>gb", ":Git blame<CR>", { desc = "Git blame" })
            vim.keymap.set("n", "<leader>gl", ":Git log --oneline --graph<CR>", { desc = "Git log" })

            vim.keymap.set("n", "<leader>gp", function()
                local branch = vim.fn.FugitiveHead()

                if branch == "" or branch == "HEAD" then
                    vim.notify("Could not determine current branch.", vim.log.levels.ERROR)
                    return
                end

                local cmd = ":G pull origin " .. branch .. " --rebase"
                vim.fn.feedkeys(cmd, "n")
            end, { desc = "Populate :G pull origin <branch> --rebase" })
        end
    },
    {
        "tpope/vim-rhubarb",
        dependencies = {
            "tpope/vim-fugitive",
        },
        setup = function()
            vim.keymap.set("n", "<leader>go", ":GBrowse!<CR>", { desc = "Yank github url" })
        end
    }
}
