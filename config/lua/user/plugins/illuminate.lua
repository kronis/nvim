return {
  "RRethy/vim-illuminate",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require("illuminate").configure({
      providers = { "lsp", "treesitter", "regex" },
      delay = 100,
      filetypes_denylist = { "NvimTree", "alpha", "TelescopePrompt" },
    })
  end,
}
