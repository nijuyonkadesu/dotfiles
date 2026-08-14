return {
  dir = "~/redacted/revdict.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "m00qek/baleia.nvim",
  },
  cmd = { "Revdict" },
  keys = {
    { "<leader>rd", "<cmd>Revdict<cr>", desc = "revdict live lookup", mode = { "n" } },
  },
  config = function()
    require("revdict").setup()
  end,
}

