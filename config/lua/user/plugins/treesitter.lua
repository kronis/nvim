local status_ok, configs = pcall(require, "nvim-treesitter.configs")
if not status_ok then
	return
end

configs.setup({
  ensure_installed ={ "c", "lua", "vim", "vimdoc", "bash", "css", "html", "javascript", "json", "python", "typescript", "tsx"},
	ignore_install = { }, -- List of parsers to ignore installing
  auto_install = true,
	highlight = {
		enable = true, -- false will disable the whole extension
		disable = { }, -- list of language that will be disabled
	},
	autopairs = {
		enable = true,
	},
	indent = { enable = true, disable = {} },
  context_commentstring = {
    enable = true,
    enable_autocmd = false,
  }
})
