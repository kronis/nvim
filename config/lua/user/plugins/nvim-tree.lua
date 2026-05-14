return {
  "nvim-tree/nvim-tree.lua",
  cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeFindFile" },
  keys = {
    { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file tree" },
  },
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    sort_by = "case_sensitive",
    view = { width = 30 },
    renderer = { group_empty = true },
    filters = { dotfiles = false },
    git = { enable = true, ignore = false },
    actions = { open_file = { quit_on_open = false } },
  },
}
