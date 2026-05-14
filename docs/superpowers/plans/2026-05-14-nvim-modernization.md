# Neovim Config Modernization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate this 2023-era packer.nvim Neovim config to a 2026-current lazy.nvim setup on Neovim 0.12, replacing all archived/unmaintained plugins, simplifying the installer, and preserving the user's keymaps/options/snippets.

**Architecture:** lazy.nvim plugin manager with one spec file per plugin under `config/lua/user/plugins/`. LSP via Neovim 0.11+ `vim.lsp.config()` + `mason-lspconfig` v2 (`automatic_enable = true`). Formatting via `conform.nvim` (replaces null-ls), linting via `nvim-lint`. Installer symlinks `<repo>/config` → `~/.config/nvim` with `--dev` flag for the maintainer.

**Tech Stack:** Neovim 0.12.2, Lua, lazy.nvim, mason.nvim, mason-lspconfig.nvim, nvim-lspconfig, nvim-cmp, conform.nvim, nvim-lint, telescope.nvim, nvim-treesitter, tokyonight.nvim, bash (installer).

**Spec:** [`docs/superpowers/specs/2026-05-14-nvim-update-design.md`](../specs/2026-05-14-nvim-update-design.md)

**Engineer context note:** Throughout this plan, `:checkhealth` and `nvim --headless` smoke tests stand in for traditional unit tests — an nvim config has no test suite. "Verification" means: the editor loads, the named keymap or command works, and `:messages` shows no errors.

---

## Task 1: Phase 0 — Safety net

**Files:**
- No file changes; git operations only.

- [ ] **Step 1: Verify clean working tree**

Run: `git status`
Expected: `nothing to commit, working tree clean` (the spec was committed in `83d63a1`).

- [ ] **Step 2: Inspect stashes one last time, then drop both**

Run: `git stash list`
Expected: two stashes (`stash@{0}` and `stash@{1}`).

Run: `git stash drop stash@{0}`
Then: `git stash drop stash@{0}` again (the second stash shifts to index 0 after the first drop).
Run: `git stash list`
Expected: empty.

(Stashes remain recoverable from reflog for ~90 days if needed: `git fsck --unreachable | grep commit`.)

- [ ] **Step 3: Tag current main for rollback**

Run: `git tag pre-modernize-2026`
Run: `git tag --list pre-modernize-2026`
Expected: `pre-modernize-2026`

- [ ] **Step 4: Create the working branch**

Run: `git checkout -b modernize-2026`
Run: `git branch --show-current`
Expected: `modernize-2026`

- [ ] **Step 5: No commit needed for Phase 0**

Phase 0 is git-state setup. Move on to Task 2.

---

## Task 2: Phase 1 — Strip packer-era plugin config

**Files:**
- Delete: `config/lua/user/plugin-setup.lua`
- Delete: `config/lua/user/plugins/init.lua`
- Delete: `config/lua/user/plugins/lsp/` (entire directory)
- Delete: `config/lua/user/core/colorscheme.lua` (moves into plugin spec)
- Delete: `config/plugin/packer_compiled.lua`
- Delete: all files directly under `config/lua/user/plugins/` (re-authored in later tasks)

- [ ] **Step 1: Delete the packer plugin list and the plugins init**

Run:
```bash
rm config/lua/user/plugin-setup.lua
rm config/lua/user/plugins/init.lua
```

- [ ] **Step 2: Delete the LSP subdirectory**

Run: `rm -r config/lua/user/plugins/lsp`

- [ ] **Step 3: Delete each old plugin config file**

Run:
```bash
rm config/lua/user/plugins/alpha.lua
rm config/lua/user/plugins/autopairs.lua
rm config/lua/user/plugins/barbecue.lua
rm config/lua/user/plugins/bufferline.lua
rm config/lua/user/plugins/cmp.lua
rm config/lua/user/plugins/comment.lua
rm config/lua/user/plugins/fidget.lua
rm config/lua/user/plugins/gitsigns.lua
rm config/lua/user/plugins/indent-blankline.lua
rm config/lua/user/plugins/lualine.lua
rm config/lua/user/plugins/nvim-notify.lua
rm config/lua/user/plugins/nvim-surround.lua
rm config/lua/user/plugins/nvim-tree-on-attach.lua
rm config/lua/user/plugins/nvim-tree.lua
rm config/lua/user/plugins/symbols-outline.lua
rm config/lua/user/plugins/telescope.lua
rm config/lua/user/plugins/toggleterm.lua
rm config/lua/user/plugins/treesitter.lua
rm config/lua/user/plugins/typescript.lua
rm config/lua/user/plugins/whichkey.lua
```

(`config/lua/user/plugins/` should now be an empty directory. It will be re-populated in later tasks.)

- [ ] **Step 4: Delete the committed packer compile output**

Run:
```bash
rm config/plugin/packer_compiled.lua
rmdir config/plugin
```

- [ ] **Step 5: Delete core/colorscheme.lua (apply moves into plugin spec)**

Run: `rm config/lua/user/core/colorscheme.lua`

- [ ] **Step 6: Verify what remains**

Run: `find config -type f | sort`
Expected:
```
config/init.lua
config/lua/user/core/init.lua
config/lua/user/core/keymaps.lua
config/lua/user/core/options.lua
config/snippets/package.json
config/snippets/typescript.json
```

- [ ] **Step 7: Commit**

```bash
git add -A config/
git commit -m "chore: strip packer-era plugin config

Removes packer.nvim's plugin-setup.lua, the per-plugin user/plugins/*
files, the committed packer_compiled.lua, the LSP subdirectory, and
core/colorscheme.lua (the colorscheme apply will move into the
tokyonight plugin spec in Phase 3).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Phase 2 — Lazy.nvim bootstrap + core wiring

**Files:**
- Create: `config/lua/user/lazy.lua`
- Modify: `config/init.lua`
- Modify: `config/lua/user/core/init.lua`
- Modify: `config/lua/user/core/keymaps.lua` (remove dead copilot block)
- Create: `config/lua/user/core/autocmds.lua`

- [ ] **Step 1: Create the lazy.nvim bootstrap**

Create `config/lua/user/lazy.lua` with:

```lua
-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { import = "user.plugins" },
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = { enabled = false },
  change_detection = { notify = false },
})
```

- [ ] **Step 2: Rewrite the entry point**

Overwrite `config/init.lua` with:

```lua
require("user.core")
require("user.lazy")
```

- [ ] **Step 3: Update user.core init to drop colorscheme require**

Overwrite `config/lua/user/core/init.lua` with:

```lua
require("user.core.options")
require("user.core.keymaps")
require("user.core.autocmds")
```

- [ ] **Step 4: Remove the dead copilot block at the bottom of keymaps.lua**

Open `config/lua/user/core/keymaps.lua`. The last ~6 lines are commented-out copilot mappings. Delete this block:

```lua
--  -- vim.keymap.set("i", "<C-l>", "copilot#Accept()", {expr=true})
-- keymap("i", "<C-l>", "copilot#Accept()", {silent =true, expr=true})
-- vim.keymap.set("i", "<C-j>", "copilot#Next()", {expr=true})
-- vim.keymap.set("i", "<C-k>", "copilot#Previous()", {expr=true})
--         -- imap <silent><script><expr> <C-J> copilot#Accept("\<CR>")
--         -- let g:copilot_no_tab_map = v:true
```

Leave the rest of the file intact.

- [ ] **Step 5: Create the autocmds file**

Create `config/lua/user/core/autocmds.lua`:

```lua
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Highlight on yank
autocmd("TextYankPost", {
  group = augroup("highlight_yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
  end,
})

-- Press q to close help / quickfix / man / lspinfo windows
autocmd("FileType", {
  group = augroup("close_with_q", { clear = true }),
  pattern = { "help", "qf", "man", "lspinfo", "checkhealth", "notify" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})
```

- [ ] **Step 6: Verify nvim boots and lazy.nvim self-installs**

Run: `nvim --headless +"qa" 2>&1 | head -40`
Expected: no error output (lazy.nvim clones itself silently to `~/.local/share/nvim/lazy/lazy.nvim`).

Then run interactively: `nvim`
Expected: editor opens, no error popups. Run `:Lazy` — opens the lazy UI showing the lazy.nvim plugin itself, no other plugins yet. Run `:messages` — no errors. Quit with `:qa`.

- [ ] **Step 7: Commit**

```bash
git add config/
git commit -m "feat: bootstrap lazy.nvim and core autocmds

- Add config/lua/user/lazy.lua with stable-branch bootstrap, imports
  user.plugins as a directory of spec files.
- Rewrite config/init.lua to require core then lazy.
- Drop core/colorscheme require (moves into plugins/colorscheme).
- Add core/autocmds.lua: yank highlight, 'q' to close help/qf/lspinfo.
- Remove dead copilot block at the bottom of keymaps.lua.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Phase 3a — Colorscheme

**Files:**
- Create: `config/lua/user/plugins/colorscheme.lua`

- [ ] **Step 1: Write the tokyonight plugin spec**

Create `config/lua/user/plugins/colorscheme.lua`:

```lua
return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    transparent = false,
    terminal_colors = true,
    styles = {
      comments = { italic = true },
      keywords = { italic = true },
      sidebars = "dark",
      floats = "dark",
    },
    sidebars = { "qf", "help" },
  },
  config = function(_, opts)
    require("tokyonight").setup(opts)
    vim.cmd.colorscheme("tokyonight")
  end,
}
```

- [ ] **Step 2: Install the plugin headlessly**

Run: `nvim --headless "+Lazy! sync" +qa 2>&1 | tail -20`
Expected: lazy reports "tokyonight.nvim" installed/cloned. No errors.

- [ ] **Step 3: Verify the colorscheme loads**

Run: `nvim` then `:colorscheme` (just the command, no argument) → prints `tokyonight`. Run `:messages` → no "Colorscheme not found" notification. Quit `:qa`.

- [ ] **Step 4: Commit**

```bash
git add config/lua/user/plugins/colorscheme.lua
git commit -m "feat(plugins): add tokyonight colorscheme

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: Phase 3b — UI shell (alpha, lualine, bufferline, nvim-tree, which-key, indent-blankline, notify, fidget)

**Files:**
- Create: `config/lua/user/plugins/alpha.lua`
- Create: `config/lua/user/plugins/lualine.lua`
- Create: `config/lua/user/plugins/bufferline.lua`
- Create: `config/lua/user/plugins/nvim-tree.lua`
- Create: `config/lua/user/plugins/which-key.lua`
- Create: `config/lua/user/plugins/indent-blankline.lua`
- Create: `config/lua/user/plugins/notify.lua`
- Create: `config/lua/user/plugins/fidget.lua`

- [ ] **Step 1: alpha (dashboard)**

Create `config/lua/user/plugins/alpha.lua`:

```lua
return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")
    dashboard.section.header.val = {
      "                                                     ",
      "  ██╗  ██╗██████╗  ██████╗ ███╗   ██╗██╗   ██╗██╗███╗   ███╗",
      "  ██║ ██╔╝██╔══██╗██╔═══██╗████╗  ██║██║   ██║██║████╗ ████║",
      "  █████╔╝ ██████╔╝██║   ██║██╔██╗ ██║██║   ██║██║██╔████╔██║",
      "  ██╔═██╗ ██╔══██╗██║   ██║██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║",
      "  ██║  ██╗██║  ██║╚██████╔╝██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║",
      "  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝",
      "                                                     ",
    }
    dashboard.section.buttons.val = {
      dashboard.button("f", "  Find file", ":Telescope find_files <CR>"),
      dashboard.button("e", "  New file", ":ene <BAR> startinsert <CR>"),
      dashboard.button("r", "  Recent files", ":Telescope oldfiles <CR>"),
      dashboard.button("g", "  Live grep", ":Telescope live_grep <CR>"),
      dashboard.button("c", "  Config", ":e $MYVIMRC <CR>"),
      dashboard.button("q", "  Quit", ":qa<CR>"),
    }
    dashboard.section.footer.val = "kronvim"
    alpha.setup(dashboard.opts)
  end,
}
```

- [ ] **Step 2: lualine (statusline)**

Create `config/lua/user/plugins/lualine.lua`:

```lua
return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      theme = "tokyonight",
      globalstatus = true,
      section_separators = { left = "", right = "" },
      component_separators = { left = "│", right = "│" },
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch", "diff", "diagnostics" },
      lualine_c = { { "filename", path = 1 } },
      lualine_x = { "filetype" },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
  },
}
```

- [ ] **Step 3: bufferline (buffer tabs)**

Create `config/lua/user/plugins/bufferline.lua`:

```lua
return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "moll/vim-bbye",
  },
  opts = {
    options = {
      close_command = "Bdelete! %d",
      right_mouse_command = "Bdelete! %d",
      diagnostics = "nvim_lsp",
      offsets = {
        { filetype = "NvimTree", text = "Explorer", separator = true, text_align = "left" },
      },
      show_buffer_close_icons = true,
      show_close_icon = false,
      always_show_bufferline = true,
    },
  },
}
```

- [ ] **Step 4: nvim-tree (file explorer)**

Create `config/lua/user/plugins/nvim-tree.lua`:

```lua
return {
  "nvim-tree/nvim-tree.lua",
  cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeFindFile" },
  keys = {
    { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file tree" },
  },
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    sort_by = "case_sensitive",
    view = { width = 30 },
    renderer = { group_empty = true },
    filters = { dotfiles = false },
    git = { enable = true, ignore = false },
    actions = { open_file = { quit_on_open = false } },
  },
}
```

- [ ] **Step 5: which-key**

Create `config/lua/user/plugins/which-key.lua`:

```lua
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    spec = {
      { "<leader>c", group = "code" },
      { "<leader>f", group = "find/file" },
      { "<leader>g", group = "git" },
      { "<leader>l", group = "lsp" },
      { "<leader>s", group = "search/symbols" },
    },
  },
  keys = {
    {
      "<leader>?",
      function() require("which-key").show({ global = false }) end,
      desc = "Buffer local keymaps",
    },
  },
}
```

- [ ] **Step 6: indent-blankline (ibl main)**

Create `config/lua/user/plugins/indent-blankline.lua`:

```lua
return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    indent = { char = "│" },
    scope = { enabled = false },
  },
}
```

- [ ] **Step 7: nvim-notify**

Create `config/lua/user/plugins/notify.lua`:

```lua
return {
  "rcarriga/nvim-notify",
  event = "VeryLazy",
  opts = {
    timeout = 3000,
    max_height = function() return math.floor(vim.o.lines * 0.75) end,
    max_width = function() return math.floor(vim.o.columns * 0.75) end,
    render = "wrapped-compact",
  },
  init = function()
    vim.notify = function(...)
      return require("notify")(...)
    end
  end,
}
```

- [ ] **Step 8: fidget (LSP progress)**

Create `config/lua/user/plugins/fidget.lua`:

```lua
return {
  "j-hui/fidget.nvim",
  event = "LspAttach",
  opts = {
    notification = { window = { winblend = 0 } },
  },
}
```

- [ ] **Step 9: Install and verify**

Run: `nvim --headless "+Lazy! sync" +qa 2>&1 | tail -30`
Expected: lazy reports clone/install for each new plugin, no errors.

Open `nvim` interactively. Verify:
- Dashboard appears with the kronvim ASCII header and `f / e / r / g / c / q` buttons.
- `:NvimTreeToggle` opens a file tree on the left.
- `<leader>e` toggles the same tree.
- `<leader>` (just leader, then wait 300ms) → which-key popup lists groups `code`, `find/file`, `git`, `lsp`, `search/symbols`.
- Statusline shows mode, branch (or empty), filename, location.
- Bufferline shows the current buffer.
- Indent guides visible in a file with indented content.
- `:messages` → no errors.

- [ ] **Step 10: Commit**

```bash
git add config/lua/user/plugins/
git commit -m "feat(plugins): add UI shell (alpha, lualine, bufferline, nvim-tree, which-key, indent-blankline, notify, fidget)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: Phase 3c — Editing aids (telescope, treesitter, autopairs, comment, surround, illuminate)

**Files:**
- Create: `config/lua/user/plugins/telescope.lua`
- Create: `config/lua/user/plugins/treesitter.lua`
- Create: `config/lua/user/plugins/autopairs.lua`
- Create: `config/lua/user/plugins/comment.lua`
- Create: `config/lua/user/plugins/surround.lua`
- Create: `config/lua/user/plugins/illuminate.lua`

- [ ] **Step 1: telescope**

Create `config/lua/user/plugins/telescope.lua`:

```lua
return {
  "nvim-telescope/telescope.nvim",
  cmd = "Telescope",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<cr>",  desc = "Find files" },
    { "<leader>fg", "<cmd>Telescope live_grep<cr>",   desc = "Live grep" },
    { "<leader>fb", "<cmd>Telescope buffers<cr>",     desc = "Buffers" },
    { "<leader>fh", "<cmd>Telescope help_tags<cr>",   desc = "Help tags" },
    { "<leader>fr", "<cmd>Telescope oldfiles<cr>",    desc = "Recent files" },
  },
  opts = {
    defaults = {
      path_display = { "truncate" },
      mappings = {
        i = {
          ["<C-j>"] = "move_selection_next",
          ["<C-k>"] = "move_selection_previous",
        },
      },
    },
  },
}
```

- [ ] **Step 2: treesitter + autotag + context-commentstring**

Create `config/lua/user/plugins/treesitter.lua`:

```lua
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
```

- [ ] **Step 3: autopairs**

Create `config/lua/user/plugins/autopairs.lua`:

```lua
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
```

- [ ] **Step 4: comment**

Create `config/lua/user/plugins/comment.lua`:

```lua
return {
  "numToStr/Comment.nvim",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
  config = function()
    require("Comment").setup({
      pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
    })
  end,
}
```

- [ ] **Step 5: surround**

Create `config/lua/user/plugins/surround.lua`:

```lua
return {
  "kylechui/nvim-surround",
  event = { "BufReadPost", "BufNewFile" },
  version = "*",
  opts = {},
}
```

- [ ] **Step 6: illuminate**

Create `config/lua/user/plugins/illuminate.lua`:

```lua
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
```

- [ ] **Step 7: Install and verify**

Run: `nvim --headless "+Lazy! sync" +qa 2>&1 | tail -20`
Expected: clones for telescope/treesitter/etc., no errors. Treesitter will start parsers downloading on first file open.

Open `nvim some-file.ts` interactively. Verify:
- `<leader>ff` opens Telescope find files.
- `<leader>fg` opens Telescope live_grep.
- `:TSInstallInfo` shows the ensure_installed languages installed (or installing).
- `gcc` toggles a line comment.
- In a `.tsx` file, typing `<div>` and pressing `>` auto-closes the tag.
- `cs"'` swaps surrounding `"` to `'`.
- Cursor on a variable name → other occurrences highlight after 100ms.
- `:messages` → no errors (treesitter `auto_install` may print info, that's fine).

- [ ] **Step 8: Commit**

```bash
git add config/lua/user/plugins/
git commit -m "feat(plugins): add editing aids (telescope, treesitter, autopairs, comment, surround, illuminate)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: Phase 3d — Git + breadcrumbs (gitsigns, barbecue)

**Files:**
- Create: `config/lua/user/plugins/gitsigns.lua`
- Create: `config/lua/user/plugins/barbecue.lua`

- [ ] **Step 1: gitsigns**

Create `config/lua/user/plugins/gitsigns.lua`:

```lua
return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    signs = {
      add          = { text = "▎" },
      change       = { text = "▎" },
      delete       = { text = "" },
      topdelete    = { text = "" },
      changedelete = { text = "▎" },
    },
    on_attach = function(buffer)
      local gs = package.loaded.gitsigns
      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = buffer, desc = desc })
      end
      map("n", "]h", gs.next_hunk, "Next hunk")
      map("n", "[h", gs.prev_hunk, "Prev hunk")
      map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
      map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Blame line")
      map("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
      map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
      map("v", "<leader>gs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage hunk (range)")
    end,
  },
}
```

- [ ] **Step 2: barbecue (winbar breadcrumbs)**

Create `config/lua/user/plugins/barbecue.lua`:

```lua
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
```

- [ ] **Step 3: Install and verify**

Run: `nvim --headless "+Lazy! sync" +qa 2>&1 | tail -10`
Expected: no errors.

Make a quick edit to a tracked file to verify gitsigns shows a `▎` in the gutter. Then `:qa` without saving.

Open a `.lua` file with `nvim config/lua/user/core/options.lua`. Barbecue shows a path breadcrumb in the winbar (will show document symbols once LSP attaches in the next task).

- [ ] **Step 4: Commit**

```bash
git add config/lua/user/plugins/
git commit -m "feat(plugins): add gitsigns and barbecue breadcrumbs

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 8: Phase 3e — Completion + snippets

**Files:**
- Create: `config/lua/user/plugins/completion.lua`

- [ ] **Step 1: Create the cmp + luasnip spec**

Create `config/lua/user/plugins/completion.lua`:

```lua
return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-nvim-lua",
    "hrsh7th/cmp-nvim-lsp-signature-help",
    "saadparwaiz1/cmp_luasnip",
    {
      "L3MON4D3/LuaSnip",
      version = "v2.*",
      build = "make install_jsregexp",
      dependencies = { "rafamadriz/friendly-snippets" },
      config = function()
        require("luasnip.loaders.from_vscode").lazy_load()
        require("luasnip.loaders.from_vscode").lazy_load({
          paths = { vim.fn.stdpath("config") .. "/snippets" },
        })
      end,
    },
  },
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")

    cmp.setup({
      snippet = {
        expand = function(args) luasnip.lsp_expand(args.body) end,
      },
      window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = false }),
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      }),
      sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "nvim_lsp_signature_help" },
        { name = "luasnip" },
        { name = "nvim_lua" },
      }, {
        { name = "buffer" },
        { name = "path" },
      }),
    })
  end,
}
```

- [ ] **Step 2: Install and verify**

Run: `nvim --headless "+Lazy! sync" +qa 2>&1 | tail -10`
Expected: clones cmp + sources + LuaSnip + friendly-snippets, runs `make install_jsregexp` (may emit harmless make warnings). No errors.

Open `nvim test.ts` interactively. Enter insert mode and type `con` — completion menu appears with `console` and friends. Type `console.log` and press `Tab` after the snippet trigger — friendly-snippets / your local snippets should offer expansion. Press `<C-e>` to dismiss. `:qa!`.

- [ ] **Step 3: Commit**

```bash
git add config/lua/user/plugins/
git commit -m "feat(plugins): add nvim-cmp + luasnip + friendly-snippets

Loads vscode-style snippets from friendly-snippets and from this repo's
config/snippets/ directory. Pulls cmp sources for LSP, buffer, path,
lua, signature_help, and luasnip.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 9: Phase 3f — LSP (mason + lspconfig + servers)

**Files:**
- Create: `config/lua/user/plugins/lsp.lua`

- [ ] **Step 1: Write the LSP spec**

Create `config/lua/user/plugins/lsp.lua`:

```lua
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
        automatic_enable = true,
      })
    end,
  },
}
```

- [ ] **Step 2: Install everything**

Run: `nvim --headless "+Lazy! sync" +"MasonToolsInstall" +qa 2>&1 | tail -40`
Expected: lazy installs the LSP-related plugins, then mason-tool-installer queues stylua/prettierd/shfmt/shellcheck/ruff, mason-lspconfig queues the LSP servers. This may take 30–90s on first run.

Run: `nvim --headless "+lua print(vim.inspect(require('mason-lspconfig').get_installed_servers()))" +qa`
Expected: a table listing all ensure_installed servers once installation completes. If the list is short, re-run `+MasonToolsInstall` and wait — mason runs async.

Alternatively in interactive nvim: `:Mason` shows package status with ✓ for installed.

- [ ] **Step 3: Verify LSP attaches to each language**

Create `/tmp/lsp-smoke/` with one file per language:
```bash
mkdir -p /tmp/lsp-smoke && cd /tmp/lsp-smoke
printf 'const x: number = 1;\nconsole.log(x);\n' > a.ts
printf 'local x = 1\nprint(x)\n' > a.lua
printf 'x: int = 1\n' > a.py
printf '#!/bin/bash\necho hi\n' > a.sh
printf '{"foo": 1}\n' > a.json
printf '<div class="flex"></div>\n' > a.html
```

Open each in `nvim` and run `:LspInfo`. Expected attachments:
- `a.ts` → `vtsls` (and `eslint` if eslintrc is present, which there isn't here — ok).
- `a.lua` → `lua_ls`.
- `a.py` → `basedpyright`.
- `a.sh` → `bashls`.
- `a.json` → `jsonls`.
- `a.html` → `html` (and possibly `tailwindcss` if it detects classes).

Inside `a.ts`, press `K` on `x` → hover shows the type. Press `gd` on `x` in `console.log(x)` → cursor jumps to the declaration. `:qa!`.

- [ ] **Step 4: Commit**

```bash
git add config/lua/user/plugins/
git commit -m "feat(plugins): add mason + nvim-lspconfig + LSP servers

Wires up Mason + mason-lspconfig (v2 automatic_enable), mason-tool-
installer for non-LSP binaries (stylua, prettierd, shfmt, shellcheck,
ruff), and per-server config via vim.lsp.config() for lua_ls, jsonls
(schemastore), and basedpyright. Buffer-local keymaps (gd/K/<leader>ca
etc.) and nvim-navic attach on LSP attach. Capabilities advertised
from cmp_nvim_lsp.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 10: Phase 3g — Formatting + linting

**Files:**
- Create: `config/lua/user/plugins/formatting.lua`
- Create: `config/lua/user/plugins/linting.lua`

- [ ] **Step 1: conform.nvim**

Create `config/lua/user/plugins/formatting.lua`:

```lua
return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo", "FormatDisable", "FormatEnable" },
  keys = {
    {
      "<leader>cf",
      function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
      mode = { "n", "v" },
      desc = "Format buffer",
    },
  },
  ---@module "conform"
  ---@type conform.setupOpts
  opts = {
    formatters_by_ft = {
      lua        = { "stylua" },
      python     = { "ruff_format" },
      sh         = { "shfmt" },
      bash       = { "shfmt" },
      javascript = { "prettierd", "prettier", stop_after_first = true },
      typescript = { "prettierd", "prettier", stop_after_first = true },
      javascriptreact = { "prettierd", "prettier", stop_after_first = true },
      typescriptreact = { "prettierd", "prettier", stop_after_first = true },
      json       = { "prettierd", "prettier", stop_after_first = true },
      jsonc      = { "prettierd", "prettier", stop_after_first = true },
      yaml       = { "prettierd", "prettier", stop_after_first = true },
      css        = { "prettierd", "prettier", stop_after_first = true },
      html       = { "prettierd", "prettier", stop_after_first = true },
      markdown   = { "prettierd", "prettier", stop_after_first = true },
    },
    default_format_opts = {
      lsp_format = "fallback",
    },
    format_on_save = function(bufnr)
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return
      end
      return { timeout_ms = 1000, lsp_format = "fallback" }
    end,
    formatters = {
      shfmt = { prepend_args = { "-i", "2" } },
    },
  },
  init = function()
    vim.api.nvim_create_user_command("FormatDisable", function(args)
      if args.bang then
        vim.b.disable_autoformat = true
      else
        vim.g.disable_autoformat = true
      end
    end, { desc = "Disable format-on-save", bang = true })

    vim.api.nvim_create_user_command("FormatEnable", function()
      vim.b.disable_autoformat = false
      vim.g.disable_autoformat = false
    end, { desc = "Re-enable format-on-save" })

    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
}
```

- [ ] **Step 2: nvim-lint**

Create `config/lua/user/plugins/linting.lua`:

```lua
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
```

- [ ] **Step 3: Install and verify formatting**

Run: `nvim --headless "+Lazy! sync" +qa 2>&1 | tail -10`
Expected: clones conform.nvim + nvim-lint. No errors.

Create a deliberately badly-formatted Python file:
```bash
printf 'x=1\ny =2\n' > /tmp/lsp-smoke/fmt.py
```

Run: `nvim /tmp/lsp-smoke/fmt.py +"normal! Go" +"w" +qa` (the `Go` motion makes the buffer dirty so save triggers).
Then: `cat /tmp/lsp-smoke/fmt.py`
Expected: ruff has reformatted to `x = 1\ny = 2\n` (spaces around `=`).

- [ ] **Step 4: Verify linting**

Create a Python file with an unused import:
```bash
printf 'import os\nprint("hi")\n' > /tmp/lsp-smoke/lint.py
```

Open it: `nvim /tmp/lsp-smoke/lint.py`
After `BufReadPost` fires, ruff lints. Run `:lua vim.diagnostic.setqflist()` then `:copen`.
Expected: a diagnostic for `os` being unused (rule `F401`).
`:qa!`.

- [ ] **Step 5: Commit**

```bash
git add config/lua/user/plugins/
git commit -m "feat(plugins): add conform.nvim formatting + nvim-lint linting

Replaces archived null-ls. conform.nvim handles format-on-save with
:FormatDisable[!] / :FormatEnable user commands. nvim-lint runs ruff
and shellcheck on BufWritePost/BufEnter. ts/tsx/js/jsx are linted by
the eslint LSP, not nvim-lint, to avoid double-reporting.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 11: Phase 3h — Misc (toggleterm, outline)

**Files:**
- Create: `config/lua/user/plugins/toggleterm.lua`
- Create: `config/lua/user/plugins/outline.lua`

- [ ] **Step 1: toggleterm**

Create `config/lua/user/plugins/toggleterm.lua`:

```lua
return {
  "akinsho/toggleterm.nvim",
  cmd = { "ToggleTerm", "TermExec" },
  keys = {
    { [[<C-\>]], "<cmd>ToggleTerm<cr>", mode = { "n", "t" }, desc = "Toggle terminal" },
  },
  opts = {
    open_mapping = [[<C-\>]],
    direction = "float",
    float_opts = { border = "rounded" },
    shade_terminals = true,
  },
}
```

- [ ] **Step 2: outline.nvim**

Create `config/lua/user/plugins/outline.lua`:

```lua
return {
  "hedyhli/outline.nvim",
  cmd = { "Outline", "OutlineOpen" },
  keys = {
    { "<leader>so", "<cmd>Outline<cr>", desc = "Symbols outline" },
  },
  opts = {
    outline_window = { position = "right", width = 25, relative_width = true },
  },
}
```

- [ ] **Step 3: Install and verify**

Run: `nvim --headless "+Lazy! sync" +qa 2>&1 | tail -10`
Expected: clones toggleterm + outline.nvim, no errors.

Open `nvim config/lua/user/core/options.lua` interactively. Verify:
- `<C-\>` opens a floating terminal. Type `ls` Enter — files listed. `<C-\>` closes.
- `<leader>so` opens a right-side pane listing document symbols. `q` closes it (because of the close_with_q autocmd).
- `:qa!`.

- [ ] **Step 4: Commit**

```bash
git add config/lua/user/plugins/
git commit -m "feat(plugins): add toggleterm and outline.nvim

outline.nvim replaces the unmaintained simrat39/symbols-outline.nvim,
same UX (right-side symbol pane on <leader>so).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 12: Phase 4 — Installer rewrite

**Files:**
- Modify: `installer/installer.sh`
- Modify: `installer/setup-brew.sh`
- Delete: `installer/setup-cargo.sh`
- Delete: `installer/setup-luarocks.sh`
- Delete: `installer/setup-npm.sh`
- Modify: `README.md`

- [ ] **Step 1: Delete unused setup scripts**

Run:
```bash
rm installer/setup-cargo.sh
rm installer/setup-luarocks.sh
rm installer/setup-npm.sh
```

- [ ] **Step 2: Rewrite setup-brew.sh**

Overwrite `installer/setup-brew.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Install from https://brew.sh and re-run." >&2
  exit 1
fi

PACKAGES=(ripgrep fd node git)

for pkg in "${PACKAGES[@]}"; do
  if brew list --formula "$pkg" >/dev/null 2>&1; then
    echo "  ✓ $pkg already installed"
  else
    echo "  → installing $pkg"
    brew install "$pkg"
  fi
done
```

Make it executable: `chmod +x installer/setup-brew.sh`

- [ ] **Step 3: Rewrite installer.sh**

Overwrite `installer/installer.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/kronis/nvim.git}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.config/kronvim}"
NVIM_CONFIG="$HOME/.config/nvim"

DEV_MODE=0

logo() {
  cat <<'EOF'

██╗░░██╗██████╗░░█████╗░███╗░░██╗██╗░░░██╗██╗███╗░░░███╗
██║░██╔╝██╔══██╗██╔══██╗████╗░██║██║░░░██║██║████╗░████║
█████═╝░██████╔╝██║░░██║██╔██╗██║╚██╗░██╔╝██║██╔████╔██║
██╔═██╗░██╔══██╗██║░░██║██║╚████║░╚████╔╝░██║██║╚██╔╝██║
██║░╚██╗██║░░██║╚█████╔╝██║░╚███║░░╚██╔╝░░██║██║░╚═╝░██║
╚═╝░░╚═╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚══╝░░░╚═╝░░░╚═╝╚═╝░░░░░╚═╝

EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dev) DEV_MODE=1 ;;
      -h|--help)
        echo "Usage: installer.sh [--dev]"
        echo "  --dev   Symlink ~/.config/nvim to this repo (for development)"
        exit 0
        ;;
      *) echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
    shift
  done
}

ensure_deps() {
  echo "[deps] Ensuring system dependencies via Homebrew..."
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  bash "$script_dir/setup-brew.sh"
}

install_repo() {
  if [[ "$DEV_MODE" == "1" ]]; then
    INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    echo "[install] Dev mode: using repo at $INSTALL_DIR"
    return
  fi

  if [[ -d "$INSTALL_DIR/.git" ]]; then
    echo "[install] Repo exists at $INSTALL_DIR — pulling latest..."
    git -C "$INSTALL_DIR" pull --ff-only
  else
    echo "[install] Cloning $REPO_URL into $INSTALL_DIR..."
    git clone "$REPO_URL" "$INSTALL_DIR"
  fi
}

link_config() {
  local target="$INSTALL_DIR/config"

  if [[ ! -d "$target" ]]; then
    echo "[link] ERROR: $target does not exist" >&2
    exit 1
  fi

  if [[ -L "$NVIM_CONFIG" ]]; then
    echo "[link] Replacing existing symlink at $NVIM_CONFIG"
    rm "$NVIM_CONFIG"
  elif [[ -e "$NVIM_CONFIG" ]]; then
    local backup="$NVIM_CONFIG.bak-$(date +%Y%m%d-%H%M%S)"
    echo "[link] Backing up existing $NVIM_CONFIG → $backup"
    mv "$NVIM_CONFIG" "$backup"
  fi

  mkdir -p "$(dirname "$NVIM_CONFIG")"
  ln -s "$target" "$NVIM_CONFIG"
  echo "[link] Symlinked $NVIM_CONFIG → $target"
}

main() {
  logo
  parse_args "$@"
  ensure_deps
  install_repo
  link_config
  echo ""
  echo "Done. Launch nvim — lazy.nvim will install plugins on first run."
}

main "$@"
```

Make it executable: `chmod +x installer/installer.sh`

- [ ] **Step 4: Rewrite README.md**

Overwrite `README.md` with:

````markdown
# kronvim

A personal Neovim config for Neovim 0.10+ (tested on 0.12). Uses
lazy.nvim for plugin management and Mason for LSP/formatter/linter
installs. Targets TypeScript, Lua, Tailwind, Python, and Bash out of
the box.

## Install (new machine)

```bash
git clone https://github.com/kronis/nvim.git ~/.config/kronvim
~/.config/kronvim/installer/installer.sh
nvim   # lazy.nvim installs plugins; :Mason installs LSPs
```

Requires: macOS + Homebrew (the installer uses `brew` for `ripgrep`,
`fd`, `node`, `git`).

## Update

```bash
~/.config/kronvim/installer/installer.sh
# or:
cd ~/.config/kronvim && git pull && nvim +"Lazy sync" +qa
```

## Developing on this config

If you have the repo cloned somewhere else (e.g. `~/dev/github/kronis/nvim`)
and want your live `~/.config/nvim` to point at that working tree:

```bash
cd ~/dev/github/kronis/nvim
./installer/installer.sh --dev
# now any edit to config/ is live in nvim
```

## Layout

- `config/` — the nvim config (symlinked to `~/.config/nvim`)
- `installer/` — `installer.sh` and `setup-brew.sh`
- `docs/superpowers/` — design specs and implementation plans
````

- [ ] **Step 5: Smoke-test the installer in dry-run-ish mode**

Don't run the real `--dev` swap yet — that's Task 13. For now verify it parses:

Run: `bash -n installer/installer.sh && bash -n installer/setup-brew.sh && echo OK`
Expected: `OK`.

Run: `installer/installer.sh --help`
Expected: prints the usage.

- [ ] **Step 6: Commit**

```bash
git add installer/ README.md
git commit -m "feat(installer): simplify install, add --dev flag

Replaces clone-into-runtime model with direct symlink:
- Default: clone repo to ~/.config/kronvim, symlink config/ → ~/.config/nvim.
- --dev: use the repo containing the script; symlink that.
- setup-brew.sh: ripgrep, fd, node, git (only).
- Drops setup-cargo.sh, setup-luarocks.sh, setup-npm.sh.
- README rewritten with install / update / dev-loop docs.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 13: Phase 5 — Cutover and final verification

**Files:**
- No file changes; performs symlink swap + smoke test + merge.

- [ ] **Step 1: Confirm the existing symlink target**

Run: `readlink ~/.config/nvim`
Expected (before this task): `/Users/kronis/.local/share/kronvim/kronvim/config`

We're about to replace this with a symlink to the dev repo.

- [ ] **Step 2: Run the new installer in dev mode**

From the repo root (`~/dev/github/kronis/nvim`):
Run: `./installer/installer.sh --dev`
Expected output ends with:
```
[link] Symlinked /Users/kronis/.config/nvim → /Users/kronis/dev/github/kronis/nvim/config
Done. Launch nvim — lazy.nvim will install plugins on first run.
```

Run: `readlink ~/.config/nvim`
Expected: `/Users/kronis/dev/github/kronis/nvim/config`

- [ ] **Step 3: Smoke test the full editor end-to-end**

Open `nvim ~/dev/github/kronis/nvim/config/lua/user/core/options.lua`.

Run through this checklist; everything should work:
- [ ] No errors in `:messages`.
- [ ] Dashboard appeared on startup if opened with no args.
- [ ] `<leader>e` toggles nvim-tree.
- [ ] `<leader>ff` opens telescope file finder.
- [ ] `<leader>fg` live-greps.
- [ ] `<leader>` triggers which-key showing all groups.
- [ ] Statusline shows mode + branch + filename.
- [ ] Bufferline shows the current buffer.
- [ ] `:LspInfo` shows `lua_ls` attached.
- [ ] `K` on `vim.opt` shows hover docs.
- [ ] `:Mason` UI opens; all ensured packages show ✓.
- [ ] Edit and `:w` reformats with stylua.
- [ ] `<C-\>` opens floating terminal.
- [ ] `<leader>so` opens outline.
- [ ] `:qa` exits cleanly.

- [ ] **Step 4: Run :checkhealth to catch lingering issues**

Run: `nvim +"checkhealth lazy mason lsp" +qa 2>&1 | tail -60`
Expected: no ERROR rows from `lazy`, `mason`, or the LSP section. WARNINGs about optional providers (python3 host, perl host, ruby host) are fine to ignore.

- [ ] **Step 5: Delete the old runtime dir (only after Step 3 passes)**

Run: `rm -rf ~/.local/share/kronvim`
Expected: no output, no error.

- [ ] **Step 6: Push the branch and merge**

Run: `git push -u origin modernize-2026`
Then either:
- Open a PR (`gh pr create ...`) and merge through the GitHub UI, **or**
- Fast-forward locally:
  ```bash
  git checkout main
  git merge --ff-only modernize-2026
  git push origin main
  git branch -d modernize-2026
  ```

- [ ] **Step 7: Final post-merge verification**

After main is updated, open a fresh `nvim` once more. `:Lazy sync` to pick up any drift. Confirm `:checkhealth` is still clean.

- [ ] **Step 8: No file commit for this task** — cutover is operational, not code. The push/merge in Step 6 is the "ship".

---

## Rollback (if anything goes catastrophically wrong)

```bash
# Restore symlink to the old runtime (only if you haven't deleted it yet)
ln -sfn ~/.local/share/kronvim/kronvim/config ~/.config/nvim

# Or: roll the repo back to the tag
git checkout pre-modernize-2026
ln -sfn "$(pwd)/config" ~/.config/nvim
```

---

## Appendix: Spec coverage checklist

| Spec section | Implemented in task |
|---|---|
| §3.1 lazy.nvim plugin manager | Task 3 |
| §3.2 repo layout (incl. autocmds.lua, drop core/colorscheme) | Tasks 2, 3 |
| §3.3 plugin replacements (full table) | Tasks 4–11 |
| §3.4 LSP servers (vtsls, lua_ls, etc.) | Task 9 |
| §3.4 formatters (conform) | Task 10 |
| §3.4 linters (nvim-lint) | Task 10 |
| §3.4 treesitter ensure_installed | Task 6 |
| §3.5 options preserved | Task 2 (kept) |
| §3.5 keymaps preserved + new mappings | Tasks 3, 5–11 |
| §3.6 autocmds (yank highlight, q-close) | Task 3 |
| §4 installer with --dev | Task 12 |
| §4.2 backup of existing config | Task 12 (Step 3) |
| §4.3 setup-brew (ripgrep/fd/node/git) | Task 12 |
| §4.4 dropped setup scripts | Task 12 |
| §5 migration phases 0–5 | Tasks 1–13 |
| §5 rollback | This document, "Rollback" section |
| §7 success criteria | Task 13 (Step 3–4) |
