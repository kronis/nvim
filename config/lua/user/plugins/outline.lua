return {
  "hedyhli/outline.nvim",
  cmd = { "Outline", "OutlineOpen" },
  keys = {
    { "<leader>so", "<cmd>Outline<cr>", desc = "Symbols outline" },
  },
  opts = {
    outline_window = { position = "right", width = 25, relative_width = true },
  },
}
