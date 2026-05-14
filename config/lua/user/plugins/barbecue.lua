return {
  "utilyre/barbecue.nvim",
  event = "VeryLazy",
  name = "barbecue",
  version = "*",
  dependencies = {
    "SmiteshP/nvim-navic",
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    attach_navic = false,
    create_autocmd = false,
    show_dirname = false,
    show_basename = true,
  },
  config = function(_, opts)
    require("barbecue").setup(opts)
    vim.api.nvim_create_autocmd({
      "AttachedNavic", "BufWinEnter", "CursorHold", "InsertLeave",
    }, {
      group = vim.api.nvim_create_augroup("barbecue.updater", { clear = true }),
      callback = function() require("barbecue.ui").update() end,
    })
    -- navic is attached on LSP attach (see lsp.lua task)
  end,
}
