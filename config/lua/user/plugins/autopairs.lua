return {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  opts = {
    check_ts = true,
    ts_config = {
      lua = { "string", "source" },
      javascript = { "string", "template_string" },
    },
    disable_filetype = { "TelescopePrompt" },
  },
  config = function(_, opts)
    local autopairs = require("nvim-autopairs")
    autopairs.setup(opts)
    -- Integrate with cmp confirm
    local ok, cmp_autopairs = pcall(require, "nvim-autopairs.completion.cmp")
    if ok then
      local cmp = require("cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end
  end,
}
