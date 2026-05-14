return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPost", "BufWritePost", "BufNewFile" },
  config = function()
    local lint = require("lint")
    lint.linters_by_ft = {
      python = { "ruff" },
      sh     = { "shellcheck" },
      bash   = { "shellcheck" },
      -- ts/tsx/js/jsx: diagnostics come from the eslint LSP, not nvim-lint.
    }
    vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter" }, {
      group = vim.api.nvim_create_augroup("nvim_lint", { clear = true }),
      callback = function() require("lint").try_lint() end,
    })
  end,
}
