local passwd = vim.uv.os_get_passwd()

if not passwd or passwd.username ~= "shichika" then
    return {}
end

return {
    "kawre/leetcode.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
    },
    opts = {
        lang = "golang",
        image_support = false,
        storage = {
            home = "/home/shichika/redacted/practice/leet",
            cache = vim.fn.stdpath("cache") .. "/leetcode",
        },
    },
}
