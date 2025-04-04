local servers = {
	"lua_ls",
	-- "cssls",
	-- "html",
	-- "tsserver",
	--"pyright",
	-- "bashls",
	"jsonls",
	-- "typescript-language-server", -- Change from ts_ls to typescript-language-server
	-- "yamlls",
	"tailwindcss",
}
local settings = {
	ui = {
		border = "none",
		icons = {
			package_installed = "◍",
			package_pending = "◍",
			package_uninstalled = "◍",
		},
	},
	log_level = vim.log.levels.INFO,
	max_concurrent_installers = 4,
}
require("mason").setup(settings)
require("mason-lspconfig").setup({
	ensure_installed = servers,
	automatic_installation = true,
})
local lspconfig_status_ok, lspconfig = pcall(require, "lspconfig")
if not lspconfig_status_ok then
	return
end
local opts = {}
for _, server in pairs(servers) do
	opts = {
		on_attach = require("user.plugins.lsp.handlers").on_attach,
		capabilities = require("user.plugins.lsp.handlers").capabilities,
	}
	server = vim.split(server, "@")[1]
	local require_ok, conf_opts = pcall(require, "user.plugins.lsp.settings." .. server)
	if require_ok then
		opts = vim.tbl_deep_extend("force", conf_opts, opts)
	end
	
	-- Safe setup with server name mapping
	local server_mapping = {
		-- ["typescript-language-server"] = "tsserver" -- Map the package name to lspconfig server name
	}
	
	local lsp_name = server_mapping[server] or server
	
	if lspconfig[lsp_name] then
		lspconfig[lsp_name].setup(opts)
	else
		print("LSP server not found: " .. server)
	end
end