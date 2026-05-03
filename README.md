# Neovim config

Personal Neovim setup built on [`lazy.nvim`](https://github.com/folke/lazy.nvim) and [`mason.nvim`](https://github.com/williamboman/mason.nvim). Tested on Neovim 0.11+ (developed against 0.12).

## Quick start (macOS)

If you have Homebrew, the following one block installs everything most users will want:

```bash
# Required
brew install neovim git ripgrep fd

# Recommended
brew install lazygit
brew install --cask font-jetbrains-mono-nerd-font   # any Nerd Font works

# Per-language (install only what you use)
brew install go                 # Go LSP (gopls)
brew install nvm                # Node.js manager — see Node section below
brew install --cask dotnet-sdk  # C# (roslyn, csharpier, netcoredbg)

# Clone this repo into the standard config location
git clone <this-repo> ~/.config/nvim
nvim   # lazy.nvim will bootstrap and install plugins on first launch
```

After plugins install, run `:MasonToolsInstall` once (or just wait — it runs at startup) to install LSP servers and formatters via Mason, then `:TSUpdate` to build the Tree-sitter parsers.

## What you need

### Required

These are needed for the editor itself to load and for core features (find files, grep, syntax highlighting, snippets):

| Tool | Why | Install |
|---|---|---|
| **Neovim ≥ 0.11** | Uses `vim.lsp.config()` / `vim.lsp.enable()`, `vim.diagnostic.jump`, etc. | `brew install neovim` |
| **git** | `lazy.nvim` clones plugins, Mason clones some registries | usually preinstalled; `brew install git` otherwise |
| **C compiler + `make`** | Tree-sitter parsers and LuaSnip's `jsregexp` are built from source | macOS: install Xcode CLT with `xcode-select --install` |
| **`ripgrep`** | Used by `telescope.live_grep` (`<leader>fg`) | `brew install ripgrep` |
| **A Nerd Font** | Icons in Neo-tree, Lualine, Alpha dashboard, etc. (`have_nerd_font = true`) | `brew install --cask font-jetbrains-mono-nerd-font` (or any other) — then set your terminal to use it |

### Recommended

| Tool | Why | Install |
|---|---|---|
| **`fd`** | Faster file finding for `telescope.find_files` (`<leader>ff`) | `brew install fd` |
| **`lazygit`** | Bound to `<leader>tg` (opens lazygit in a floating terminal) | `brew install lazygit` |

### Per-language

You only need these for the languages you actually edit. The Mason-installed tools (`prettier`, `vtsls`, `csharpier`, etc.) all run on top of these runtimes.

#### JavaScript / TypeScript / Prisma

Requires **Node.js + npm** so Mason can install:

- `vtsls` — TypeScript/JavaScript LSP
- `prettier` — formatter
- `eslint_d` — fast ESLint daemon (only runs in projects that have an ESLint config)
- `prisma-fmt` — Prisma schema formatter

**Install Node via nvm (recommended):**

```bash
brew install nvm
mkdir -p ~/.nvm
```

Add this to your shell config (`~/.zshrc` or `~/.bashrc`):

```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] && . "$(brew --prefix)/opt/nvm/nvm.sh"
[ -s "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" ] && . "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm"
```

Reload your shell, then:

```bash
nvm install --lts
nvm use --lts
nvm alias default lts/*
```

> Note: nvm shims live in your shell. If you launch Neovim from a GUI launcher (not a shell), make sure `node` and `npm` are on Neovim's `PATH` — easiest is to launch Neovim from a terminal, or use a non-shim install (`brew install node`) instead.

#### Go

```bash
brew install go
```

Mason installs `gopls` automatically. `gofumpt` and `staticcheck` are enabled in `lua/lsp/servers.lua`.

#### C# / .NET

```bash
brew install --cask dotnet-sdk
```

This config uses [`seblyng/roslyn.nvim`](https://github.com/seblyng/roslyn.nvim) (Microsoft's official Roslyn server, the same one VS Code uses) instead of the discontinued OmniSharp. Mason installs:

- `roslyn` — C# / Razor / CSHTML LSP (via the [Crashdummyy registry](https://github.com/Crashdummyy/mason-registry), wired up in `lua/plugins/lsp-config.lua`)
- `csharpier` — formatter (driven by conform on save)
- `netcoredbg` — debug adapter, wired up in `lua/plugins/dap.lua`

The Roslyn server requires Neovim ≥ 0.12.0. Once installed, it auto-detects `.sln` / `.csproj` upward from your file. Useful commands:

| Command | Purpose |
|---|---|
| `:Roslyn target` | Pick the active solution when there are multiple |
| `:Roslyn restart` | Restart the server |
| `:Roslyn start` / `stop` | Manual control |

If you're migrating from this config's previous OmniSharp setup, uninstall the leftover server once:

```vim
:MasonUninstall omnisharp
```

#### Lua

Mason installs `lua_ls` and `stylua`. No system dependency.

## First-launch checklist

1. **Install plugins:** open Neovim — `lazy.nvim` bootstraps automatically. Wait for `:Lazy` to finish.
2. **Install Mason tools:**
   ```vim
   :MasonToolsInstall
   ```
   (or just wait — it auto-runs on startup; check progress with `:Mason`).
3. **Build Tree-sitter parsers:**
   ```vim
   :TSUpdate
   ```
4. **Verify:**
   ```vim
   :checkhealth
   ```
   Resolve any warnings about missing executables.

## Repo layout

```
init.lua                    entry point
lua/
  config/
    options.lua             vim.opt settings
    keymaps.lua             non-plugin keymaps
    autocmds.lua            yank highlight, quickfix dd
    lazy.lua                lazy.nvim bootstrap
  lsp/
    diagnostics.lua         vim.diagnostic.config
    on_attach.lua           LspAttach: keymaps + features
    servers.lua             per-server settings
  plugins/                  one file per plugin / plugin group
  terminal-maximize.lua     toggle full-size for terminal splits
```

## Keybindings

Leader is `<Space>`. Press `<leader>` and pause — `which-key.nvim` will show every available binding. A few highlights:

| Keys | Action |
|---|---|
| `<leader>ff` / `<leader>fg` | Find files / live grep (Telescope) |
| `<leader>fa` | Live grep with args (regex, glob, …) |
| `<leader>nn` / `<leader>nf` | Toggle Neo-tree / reveal current file |
| `<leader>a` / `<leader>h` | Harpoon: add / open menu |
| `<A-j>` `<A-k>` `<A-l>` `<A-n>` | Jump to Harpoon files 1–4 |
| `<leader>gs` / `<leader>gd` | Fugitive: status / diff split |
| `<leader>gh` / `<leader>gb` | Gitsigns: preview hunk / toggle blame |
| `<leader>tf` / `<leader>th` / `<leader>tg` | Toggleterm: float / horizontal / lazygit |
| `<leader>q` | Toggle quickfix list (`dd` to delete an item) |
| `<leader>f` | Format buffer (conform.nvim) |
| `<leader>l*` | LSP family: definition, references, rename, code action, … |
| `<leader>d*` | Debug (nvim-dap) — see Debugging section below |
| `[d` / `]d` | Previous / next diagnostic |
| `K` | Hover documentation |

Full list: `<leader>fk` (Telescope keymaps) or just press `<leader>` and read which-key.

## Debugging (nvim-dap)

Powered by `nvim-dap` + `nvim-dap-ui`. Currently only **C# / .NET** is wired up via `netcoredbg` (installed by Mason). Adding more languages is just a matter of adding adapters and configurations in `lua/plugins/dap.lua`.

### .NET workflow

1. Build your project: `dotnet build` (in a terminal, or `<leader>th` then `dotnet build`).
2. Place breakpoints with `<leader>db`.
3. Press `<F5>` (or `<leader>dc`) to start.
4. The dap-ui panels open automatically with stack frames, scopes, breakpoints, watches, and a REPL. They close on session exit.

### How the DLL picker works

`<F5>` (Launch netcoredbg) walks your repo from the current working directory and finds every `.csproj` whose project type can be launched (`<OutputType>Exe</OutputType>`, `<OutputType>WinExe</OutputType>`, `Microsoft.NET.Sdk.Web`, or `Microsoft.NET.Sdk.Worker`). It then globs `<projDir>/bin/Debug/net*/<ProjectName>.dll` for each and:

- **0 matches** → warns and falls back to a manual path prompt with file completion. Usually means you haven't run `dotnet build` yet.
- **1 match** → launches it directly, no prompt.
- **2+ matches** → opens a Telescope picker showing `Project (framework)  relative/path/to/Project.dll`. Type to fuzzy-filter. Multi-target projects (`<TargetFrameworks>net6.0;net8.0</TargetFrameworks>`) appear as separate entries per framework.

Class libraries are filtered out automatically — only projects that produce a runnable host show up.

### Keybindings

| Keys | Action |
|---|---|
| `<F5>` / `<leader>dc` | Continue (or start session) |
| `<F10>` | Step over |
| `<F11>` | Step into |
| `<F12>` | Step out |
| `<leader>db` | Toggle [B]reakpoint |
| `<leader>dB` | Conditional breakpoint (prompts for condition) |
| `<leader>dr` | Toggle [R]EPL |
| `<leader>dt` | [T]erminate session |
| `<leader>dl` | Run [L]ast configuration |
| `<leader>du` | Toggle DAP [U]I panels |
| `<leader>de` | [E]val expression under cursor / selection |

### Two launch configurations

Picked from `:lua require("dap").continue()` (i.e. `<F5>`):

- **Launch (netcoredbg)** — auto-detects the build output DLL and starts a fresh process.
- **Attach to process** — `dap.utils.pick_process` lets you fuzzy-pick an already-running .NET process (handy for ASP.NET hosts you started outside Neovim).

### Adding more languages later

Drop a new block into `lua/plugins/dap.lua`'s `config` function, e.g.:

```lua
dap.adapters.delve = { type = "server", port = "${port}", executable = { command = "dlv", args = { "dap", "-l", "127.0.0.1:${port}" } } }
dap.configurations.go = { { type = "delve", name = "Debug", request = "launch", program = "${workspaceFolder}" } }
```

Mason has DAP adapters for most languages (`delve`, `debugpy`, `js-debug-adapter`, `codelldb`, etc.) — install with `:MasonInstall <name>` then wire up the adapter and configurations.

## Updating

```vim
:Lazy sync          " update all plugins to lazy-lock.json's latest pull
:Mason              " then U to update LSPs/formatters
:TSUpdate           " update Tree-sitter parsers
```

## Troubleshooting

- **`vtsls` / `prettier` / `eslint_d` failed to install** — Mason needs `npm` on `PATH`. Install Node (see above). On macOS, the bundled Cursor/VS Code Node is *not* sufficient because it doesn't include `npm`.
- **`module 'nvim-treesitter.configs' not found`** — the `nvim-treesitter` repo's `main` branch is the v1.0 rewrite with a different API. This config pins `branch = "master"`. If you ever see this error, run `:Lazy clean` then `:Lazy sync` to re-clone on the correct branch.
- **Icons appear as boxes / `?`** — your terminal isn't using a Nerd Font. Set the font in your terminal settings (iTerm2, WezTerm, Ghostty, etc.).
- **`gopls` not formatting on save** — make sure `go` is on `PATH` for the shell that launched Neovim. Check with `:LspInfo`.
- **`roslyn` failed to install / not found** — Mason needs the Crashdummyy registry to find this package. It's registered in `lua/plugins/lsp-config.lua`; if you're seeing the error, run `:MasonUpdate` once after first launch so the new registry is fetched, then `:MasonInstall roslyn`. Also confirm `dotnet --info` works in your shell.
