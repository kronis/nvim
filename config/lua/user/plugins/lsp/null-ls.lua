local null_ls_status_ok, null_ls = pcall(require, "null-ls")
if not null_ls_status_ok then
	return
end

-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
local formatting = null_ls.builtins.formatting

-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
local diagnostics = null_ls.builtins.diagnostics

-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/code_actions
local code_actions = null_ls.builtins.code_actions

local h = require("null-ls.helpers")
local u = require("null-ls.utils")

null_ls.setup({
	debug = true,
	sources = {

    -- Formatting
		-- formatting.prettier.with({ extra_args = { "--no-semi", "--single-quote", "--jsx-single-quote" } }),
		formatting.prettierd,
		formatting.stylua,
		formatting.shfmt,
		formatting.eslint.with({
    cwd = h.cache.by_bufnr(function(params)
        return u.root_pattern(
            ".eslintrc",
            ".eslintrc.js",
            ".eslintrc.cjs",
            ".eslintrc.yaml",
            ".eslintrc.yml",
            ".eslintrc.json"
        )(params.bufname)
    end),
}),

    -- Diagnostics
    diagnostics.shellcheck,
		diagnostics.eslint.with({
    cwd = h.cache.by_bufnr(function(params)
        return u.root_pattern(
            ".eslintrc",
            ".eslintrc.js",
            ".eslintrc.cjs",
            ".eslintrc.yaml",
            ".eslintrc.yml",
            ".eslintrc.json"
        )(params.bufname)
    end),
}),
		diagnostics.luacheck.with({ extra_args = { "--globals " } }),

    -- Code Actions
    code_actions.gitsigns,
    code_actions.shellcheck,
    code_actions.eslint.with({
    cwd = h.cache.by_bufnr(function(params)
        return u.root_pattern(
            ".eslintrc",
            ".eslintrc.js",
            ".eslintrc.cjs",
            ".eslintrc.yaml",
            ".eslintrc.yml",
            ".eslintrc.json"
        )(params.bufname)
    end),
}),
	},
})
