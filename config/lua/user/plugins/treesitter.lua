return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = {
    "windwp/nvim-ts-autotag",
    "JoosepAlviste/nvim-ts-context-commentstring",
  },
  main = "nvim-treesitter.configs",
  opts = {
    ensure_installed = {
      "tsx", "typescript", "javascript",
      "lua", "python", "bash",
      "css", "html", "json", "yaml",
      "markdown", "markdown_inline",
      "vim", "vimdoc", "regex", "query",
    },
    sync_install = false,
    auto_install = true,
    highlight = { enable = true },
    indent = { enable = true },
    autotag = { enable = true },
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
    require("ts_context_commentstring").setup({ enable_autocmd = false })
  end,
}
