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
