# Neovim Config Modernization — Design

**Date:** 2026-05-14
**Status:** Approved (pending user spec review)
**Scope:** Full modernization of `kronis/nvim` from a packer.nvim-era (2023) config to a 2026-current setup running on Neovim 0.12.

---

## 1. Goals

- Replace abandoned/deprecated infrastructure with current-maintenance plugins.
- Preserve the user's UX: keymaps, options, colorscheme, snippets, language coverage.
- Make local development friction-free: edits to the cloned repo are live without push/pull.
- Make installation easy for other users: `git clone` + one installer script + `git pull` for updates.
- No AI/Copilot integration (user opted out).

## 2. Current state (baseline)

- Last meaningful commit on `main`: `39d7f97 All working`. Config files last touched October 2023.
- Plugin manager: `wbthomason/packer.nvim` (unmaintained since 2023).
- Layout: `config/init.lua` requires `user.core`, `user.plugin-setup`, `user.plugins`. Each plugin has a separate `lua/user/plugins/<name>.lua` setup file plus a `use(...)` entry in `plugin-setup.lua`.
- Deprecated plugins in use:
  - `jose-elias-alvarez/null-ls.nvim` (archived; superseded by conform.nvim + nvim-lint).
  - `simrat39/symbols-outline.nvim` (unmaintained; successor: `hedyhli/outline.nvim`).
  - `jose-elias-alvarez/typescript.nvim` (archived; native LSP covers it).
  - `kyazdani42/nvim-tree.lua`, `kyazdani42/nvim-web-devicons` (org renamed to `nvim-tree`).
  - `j-hui/fidget.nvim` pinned to `tag = "legacy"`.
- Committed `config/plugin/packer_compiled.lua` (should not be in VCS).
- Installed Neovim: v0.12.2. Existing config was written for 0.9/0.10 era.
- `~/.config/nvim` symlinked to `~/.local/share/kronvim/kronvim/config`.
- Unpushed work: two stashes. Both encode "I wanted symbols-outline". Decision: drop both; stashes remain in reflog for ~90 days as a safety net.

## 3. Target architecture

### 3.1 Plugin manager

`folke/lazy.nvim`. Bootstrapped in `lua/user/lazy.lua`. Plugin specs auto-imported from `lua/user/plugins/*.lua`. Each plugin file returns a lazy.nvim spec table; install metadata and `opts`/`config` live together (no separate setup file).

### 3.2 Repo layout

```
nvim/
├── README.md
├── installer/
│   ├── installer.sh        # symlink-based, supports --dev for local
│   └── setup-brew.sh       # ripgrep fd node git
└── config/                 # symlinked to ~/.config/nvim
    ├── init.lua
    ├── lua/user/
    │   ├── core/
    │   │   ├── init.lua
    │   │   ├── options.lua
    │   │   ├── keymaps.lua
    │   │   └── autocmds.lua       # NEW
    │   ├── lazy.lua               # NEW
    │   └── plugins/
    │       ├── colorscheme.lua
    │       ├── treesitter.lua
    │       ├── telescope.lua
    │       ├── lsp.lua
    │       ├── completion.lua
    │       ├── formatting.lua
    │       ├── linting.lua
    │       ├── nvim-tree.lua
    │       ├── bufferline.lua
    │       ├── lualine.lua
    │       ├── gitsigns.lua
    │       ├── which-key.lua
    │       ├── indent-blankline.lua
    │       ├── alpha.lua
    │       ├── toggleterm.lua
    │       ├── autopairs.lua
    │       ├── comment.lua
    │       ├── surround.lua
    │       ├── outline.lua
    │       ├── barbecue.lua
    │       ├── illuminate.lua
    │       ├── notify.lua
    │       └── fidget.lua
    └── snippets/
        ├── package.json
        └── typescript.json
```

Deleted from current layout:
- `config/lua/user/plugin-setup.lua`
- `config/lua/user/plugins/init.lua`
- `config/lua/user/plugins/lsp/` (whole subdir; flattened)
- `config/lua/user/core/colorscheme.lua` (colorscheme apply moves into `plugins/colorscheme.lua`'s `config` function — single source of truth, plays correctly with lazy loading)
- `config/plugin/packer_compiled.lua`
- All existing files under `config/lua/user/plugins/` (re-authored from scratch; packer-era patterns are incompatible with lazy spec shape)

### 3.3 Plugin selection

**Replacements:**

| Old | New | Reason |
|---|---|---|
| `wbthomason/packer.nvim` | `folke/lazy.nvim` | Packer unmaintained. |
| `jose-elias-alvarez/null-ls.nvim` | `stevearc/conform.nvim` + `mfussenegger/nvim-lint` | Modern split for formatters/linters. |
| `simrat39/symbols-outline.nvim` | `hedyhli/outline.nvim` | Active maintenance, same UX. |
| `jose-elias-alvarez/typescript.nvim` | (none) | Subsumed by `vtsls` LSP. |
| `kyazdani42/nvim-tree.lua` | `nvim-tree/nvim-tree.lua` | Org rename. |
| `kyazdani42/nvim-web-devicons` | `nvim-tree/nvim-web-devicons` | Org rename. |
| `j-hui/fidget.nvim` @ `legacy` tag | `j-hui/fidget.nvim` (current) | Drop legacy pin. |
| `ray-x/lsp_signature.nvim` | `hrsh7th/cmp-nvim-lsp-signature-help` | Lighter; lives inside cmp. |
| `github/copilot.vim` | (removed) | User opted out. |

**Kept (with version updates):** `nvim-lua/plenary.nvim`, `windwp/nvim-autopairs`, `numToStr/Comment.nvim`, `JoosepAlviste/nvim-ts-context-commentstring`, `akinsho/bufferline.nvim`, `moll/vim-bbye`, `nvim-lualine/lualine.nvim`, `akinsho/toggleterm.nvim`, `lukas-reineke/indent-blankline.nvim` (ibl main), `goolord/alpha-nvim`, `folke/which-key.nvim`, `folke/tokyonight.nvim`, `hrsh7th/nvim-cmp` + `cmp-buffer`/`cmp-path`/`cmp-nvim-lsp`/`cmp-nvim-lua`/`cmp_luasnip`, `L3MON4D3/LuaSnip`, `rafamadriz/friendly-snippets`, `neovim/nvim-lspconfig`, `williamboman/mason.nvim`, `williamboman/mason-lspconfig.nvim`, `WhoIsSethDaniel/mason-tool-installer.nvim` (new addition), `RRethy/vim-illuminate`, `nvim-telescope/telescope.nvim`, `nvim-treesitter/nvim-treesitter`, `windwp/nvim-ts-autotag`, `SmiteshP/nvim-navic`, `lewis6991/gitsigns.nvim`, `utilyre/barbecue.nvim`, `kylechui/nvim-surround`, `rcarriga/nvim-notify`, `b0o/SchemaStore.nvim` (new addition for jsonls schemas).

### 3.4 Language coverage

LSP servers via `mason-lspconfig` `ensure_installed`:

| Language | Server |
|---|---|
| TypeScript / JavaScript / TSX | `vtsls` |
| Lua | `lua_ls` (configured with Neovim runtime/`vim.*` globals) |
| Tailwind CSS | `tailwindcss` |
| Python | `basedpyright` |
| Bash | `bashls` |
| JSON | `jsonls` (+ schemastore) |
| HTML | `html` |
| CSS | `cssls` |
| ESLint | `eslint` |

Formatters via `conform.nvim` (format-on-save by default, opt-out via `:FormatDisable` user command):

| Filetype | Formatter |
|---|---|
| ts, tsx, js, jsx, json, css, html, md, yaml | `prettierd` (falls back to `prettier`) |
| lua | `stylua` |
| python | `ruff_format` |
| sh, bash | `shfmt` |

Linters via `nvim-lint` (on `BufWritePost` + `BufEnter`):

| Filetype | Linter |
|---|---|
| python | `ruff` |
| sh, bash | `shellcheck` |

ts/tsx/js/jsx are not run through nvim-lint — diagnostics come from the `eslint` LSP, which already provides them and avoids double-reporting.

All non-LSP tools (formatters/linters) installed via `mason-tool-installer`.

Treesitter `ensure_installed`: `tsx`, `typescript`, `javascript`, `lua`, `python`, `bash`, `tailwindcss`, `css`, `html`, `json`, `markdown`, `markdown_inline`, `yaml`, `vim`, `vimdoc`, `regex`, `query`.

### 3.5 Options and keymaps

`config/lua/user/core/options.lua` — kept verbatim. Includes: leader=space, relativenumber, smartcase, undofile, expandtab, shiftwidth=2, termguicolors, clipboard=unnamedplus, cursorline, signcolumn=yes, etc.

`config/lua/user/core/keymaps.lua` — kept; commented-out copilot block at the bottom removed.

New keymaps added in plugin spec files (each plugin owns its own):
- Telescope: `<leader>ff` files, `<leader>fg` live_grep, `<leader>fb` buffers, `<leader>fh` help.
- LSP buffer-local (in lsp.lua on_attach): `gd`, `gD`, `gi`, `gr`, `K`, `<leader>ca` (code action), `<leader>rn` (rename), `[d`/`]d` (next/prev diagnostic).
- Outline: `<leader>so` toggle.
- Conform manual format: `<leader>cf` (lives under the `<leader>c` "code" group, not `<leader>f` which is reserved for find/file).
- Which-key registers groups for `<leader>c` (code), `<leader>f` (find/file), `<leader>g` (git), `<leader>l` (lsp), `<leader>s` (search/symbols).

### 3.6 Autocmds (`core/autocmds.lua`)

- `TextYankPost` → highlight yanked region.
- `FileType` for the Neovim help/quickfix/etc. → `q` closes.
- Format-on-save: handled inside `conform.nvim` opts, not autocmds.lua, to keep concerns isolated.

## 4. Installer flow

### 4.1 Behavior

`installer/installer.sh` operates in two modes:

- **Default:** clones `https://github.com/kronis/nvim.git` into `~/.config/kronvim/` (or `git pull --ff-only` if it already exists), then symlinks `~/.config/kronvim/config` → `~/.config/nvim`.
- **`--dev`:** uses the repo directory containing the script itself (resolved from `$(cd "$(dirname "$0")/.." && pwd)`); symlinks its `config/` to `~/.config/nvim`. Lets the maintainer edit the dev repo directly and have changes live without push/pull.

### 4.2 Safety

- Uses `set -euo pipefail`.
- If `~/.config/nvim` is a real directory (not a symlink), it's renamed to `~/.config/nvim.bak-<timestamp>`; never deleted.
- If `~/.config/nvim` is a symlink, replaced without prompting.
- Re-running is idempotent: existing repo → `git pull --ff-only`; existing symlink → replaced.

### 4.3 Dependencies (`setup-brew.sh`)

Installs (idempotent via `brew install`): `ripgrep`, `fd`, `node`, `git`. Everything else (LSPs, formatters, linters) is handled inside Neovim by Mason.

### 4.4 Files dropped from installer

- `setup-npm.sh` (Mason handles node-based tools internally)
- `setup-cargo.sh` (no Rust-based tools required)
- `setup-luarocks.sh` (lazy.nvim doesn't need luarocks)

### 4.5 User workflows

**First-time install (any user):**
```bash
git clone https://github.com/kronis/nvim.git ~/.config/kronvim
~/.config/kronvim/installer/installer.sh
nvim   # lazy.nvim installs plugins on first run
```

**Update:**
```bash
~/.config/kronvim/installer/installer.sh
# or: cd ~/.config/kronvim && git pull && nvim +"Lazy sync"
```

**Maintainer dev loop:**
```bash
cd /Users/kronis/dev/github/kronis/nvim
./installer/installer.sh --dev    # one-time
# edit anything in config/ → reopen nvim or :source % → changes live
git push                          # only when shipping
```

## 5. Migration plan

### Phase 0 — Safety net

1. `git stash drop stash@{0}` twice (drops both stashes; reflog keeps them ~90 days).
2. `git checkout -b modernize-2026`.
3. `git tag pre-modernize-2026` for rollback.

### Phase 1 — Strip the old (1 commit)

Delete: `config/lua/user/plugin-setup.lua`, `config/lua/user/plugins/init.lua`, `config/lua/user/plugins/lsp/` (whole dir), every file under `config/lua/user/plugins/`, `config/plugin/packer_compiled.lua`.

Keep: `config/lua/user/core/` and `config/snippets/`.

Commit: `chore: strip packer-era plugin config`.

### Phase 2 — Lazy bootstrap + core (1 commit)

1. Write `config/lua/user/lazy.lua` with standard lazy bootstrap + `{ import = "user.plugins" }`.
2. Update `config/init.lua` to `require("user.core")` then `require("user.lazy")`.
3. Add `config/lua/user/core/autocmds.lua`.
4. Update `config/lua/user/core/init.lua` to require `options`, `keymaps`, `autocmds` (drop the `colorscheme` require; the plugin owns that).
5. Delete `config/lua/user/core/colorscheme.lua`.
6. Remove dead copilot block at bottom of `keymaps.lua`.

**Verification:** `nvim` opens, lazy self-installs, lazy UI shows zero plugins, `:messages` clean.

Commit: `feat: add lazy.nvim bootstrap and core autocmds`.

### Phase 3 — Plugins, one logical group per commit

Each step ends with `nvim --headless +"Lazy sync" +qa`, then interactive smoke test of the listed commands.

1. **Colorscheme** — `colorscheme.lua` (tokyonight). Verify: colors load, no fallback notify.
2. **UI shell** — alpha, lualine, bufferline, nvim-tree, which-key, indent-blankline, notify, fidget. Verify: dashboard, statusline, buffer tabs, `<leader>e` file tree, `<leader>` triggers which-key.
3. **Editing aids** — telescope, treesitter (+ts-autotag, ts-context-commentstring), autopairs, comment, surround, illuminate. Verify: `<leader>ff`, `<leader>fg`, `:TSInstallInfo` shows ensured langs, `gcc` toggles comment, `cs"'` swaps surround.
4. **Git** — gitsigns, barbecue + nvim-navic. Verify: gutter signs on modified file, breadcrumb in winbar.
5. **Completion + snippets** — nvim-cmp + sources, luasnip + friendly-snippets, snippets/ dir loaded via `luasnip.loaders.from_vscode.lazy_load({ paths = { vim.fn.stdpath("config") .. "/snippets" } })`. Verify: completion menu in insert mode, `console.log` snippet expands in `.ts`.
6. **LSP** — mason, mason-lspconfig, mason-tool-installer, lspconfig + server configs. Verify: `:Mason` opens, ensured servers install, `:LspInfo` in `.ts` file shows vtsls attached, `gd`/`K`/diagnostics functional.
7. **Formatting + linting** — conform.nvim, nvim-lint. Verify: saving a `.ts` file runs prettier; `.py` file with lint error shows ruff diagnostic.
8. **Misc** — toggleterm, outline.nvim. Verify: `<C-\>` opens terminal, `<leader>so` opens outline.

### Phase 4 — Installer rewrite (1 commit)

1. Rewrite `installer/installer.sh` per §4.
2. Delete `setup-cargo.sh`, `setup-luarocks.sh`, `setup-npm.sh`.
3. Update `setup-brew.sh` to install `ripgrep fd node git`.
4. Rewrite `README.md` with install / update / dev-loop sections.

Don't run the new installer yet — current symlink still works during Phases 1–3.

### Phase 5 — Cut over

1. `./installer/installer.sh --dev` from the repo root → replaces the `~/.config/nvim` symlink (currently → `~/.local/share/kronvim/kronvim/config`) with one pointing at this repo's `config/`.
2. Open nvim, `:Lazy sync`, `:Mason`, smoke-test ~5 min.
3. After verification, `rm -rf ~/.local/share/kronvim/` (old runtime dir).
4. Merge `modernize-2026` → `main`, push.

### Rollback

- `git checkout pre-modernize-2026` then `ln -sfn $(pwd)/config ~/.config/nvim`.
- Or restore old layout: `ln -sfn ~/.local/share/kronvim/kronvim/config ~/.config/nvim` (if still present).

## 6. Out of scope

- AI/Copilot integration (user opted out; easy to add later as one plugin file).
- Noice.nvim / fancy command-line UI.
- DAP / debugger setup (not in current config).
- Session management (auto-session, persistence.nvim).
- Multi-OS install (installer assumes macOS + Homebrew; current setup already does).
- Rust / Go language support (user excluded).

## 7. Success criteria

- `nvim --headless +"Lazy sync" +qa` exits 0.
- `nvim --headless +"checkhealth" +qa` reports no errors from configured plugins (warnings about optional providers OK).
- All ensured LSP servers attach to a sample file of each target language.
- Format-on-save produces the expected diff in a `.ts`, `.lua`, `.py`, `.sh` file.
- `installer/installer.sh --dev` from the dev repo correctly symlinks and survives a re-run.
- A fresh-machine simulation (`HOME=/tmp/fakehome ./installer/installer.sh` against a test clone) completes without error.
