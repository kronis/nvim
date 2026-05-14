return {
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonUninstall" },
    build = ":MasonUpdate",
    opts = {
      ui = {
        border = "rounded",
        icons = {
          package_installed = "✓",
          package_pending   = "➜",
          package_uninstalled = "✗",
        },
      },
    },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    event = "VeryLazy",
    opts = {
      ensure_installed = {
        -- Formatters
        "stylua",
        "prettierd",
        "shfmt",
        -- Linters
        "shellcheck",
        -- ruff serves as both LSP-equivalent linter and formatter via conform;
        -- its package on mason is "ruff"
        "ruff",
      },
      auto_update = false,
      run_on_start = true,
    },
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
      "b0o/SchemaStore.nvim",
      "SmiteshP/nvim-navic",
    },
    config = function()
      -- Diagnostics UI
      vim.diagnostic.config({
        virtual_text = { spacing = 4, prefix = "●" },
        severity_sort = true,
        signs = true,
        underline = true,
        update_in_insert = false,
        float = { border = "rounded", source = "if_many" },
      })

      -- Capabilities advertised to all servers (cmp source)
      local capabilities = vim.tbl_deep_extend(
        "force",
        vim.lsp.protocol.make_client_capabilities(),
        require("cmp_nvim_lsp").default_capabilities()
      )

      -- Buffer-local keymaps + navic on attach
      local on_attach = function(client, bufnr)
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end
        map("n", "gd", vim.lsp.buf.definition,     "Go to definition")
        map("n", "gD", vim.lsp.buf.declaration,    "Go to declaration")
        map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
        map("n", "gr", vim.lsp.buf.references,     "References")
        map("n", "K",  vim.lsp.buf.hover,          "Hover")
        map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
        map("n", "<leader>rn", vim.lsp.buf.rename,      "Rename")
        map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Prev diagnostic")
        map("n", "]d", function() vim.diagnostic.jump({ count = 1,  float = true }) end, "Next diagnostic")
        map("n", "<leader>ld", vim.diagnostic.open_float, "Line diagnostics")

        if client.server_capabilities.documentSymbolProvider then
          local ok, navic = pcall(require, "nvim-navic")
          if ok then navic.attach(client, bufnr) end
        end
      end

      -- vim.lsp.config sets per-server defaults; mason-lspconfig calls
      -- vim.lsp.enable for installed servers automatically.
      vim.lsp.config("*", {
        capabilities = capabilities,
        on_attach = on_attach,
      })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
            telemetry = { enable = false },
          },
        },
      })

      vim.lsp.config("jsonls", {
        settings = {
          json = {
            schemas = require("schemastore").json.schemas(),
            validate = { enable = true },
          },
        },
      })

      vim.lsp.config("basedpyright", {
        settings = {
          basedpyright = {
            analysis = {
              typeCheckingMode = "standard",
              autoImportCompletions = true,
            },
          },
        },
      })

      require("mason-lspconfig").setup({
        ensure_installed = {
          "vtsls",
          "lua_ls",
          "tailwindcss",
          "basedpyright",
          "bashls",
          "jsonls",
          "html",
          "cssls",
          "eslint",
        },
        -- automatic_enable: exclude formatter/linter binaries managed by
        -- mason-tool-installer so they don't get started as fake LSP servers.
        automatic_enable = {
          exclude = { "stylua", "prettierd", "shfmt", "shellcheck", "ruff" },
        },
      })
    end,
  },
}
