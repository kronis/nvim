return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    spec = {
      { "<leader>c", group = "code" },
      { "<leader>f", group = "find/file" },
      { "<leader>g", group = "git" },
      { "<leader>l", group = "lsp" },
      { "<leader>s", group = "search/symbols" },
    },
  },
  keys = {
    {
      "<leader>?",
      function() require("which-key").show({ global = false }) end,
      desc = "Buffer local keymaps",
    },
  },
}
