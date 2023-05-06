local status_ok, typescript = pcall(require, "typescript")
if not status_ok then
	return
end

typescript.setup({
  server = {
		on_attach = require("user.plugins.lsp.handlers").on_attach,
		capabilities = require("user.plugins.lsp.handlers").capabilities,
  }
})
