# Neovim config

Personal Neovim setup built on [`lazy.nvim`](https://github.com/folke/lazy.nvim) and [`mason.nvim`](https://github.com/mason-org/mason.nvim). Requires Neovim 0.12+ (`nvim-treesitter` `main` and `roslyn.nvim` both need it).

## Quick start (Arch Linux / CachyOS)

```bash
# Required
sudo pacman -S neovim git ripgrep fd tree-sitter-cli base-devel
nvim --version | head -1   # must be 0.12+; if not, `paru -S neovim-git` (AUR)

# Recommended
sudo pacman -S lazygit wl-clipboard ttf-nerd-fonts-symbols   # xclip instead of wl-clipboard on X11

# Per-language (install only what you use)
sudo pacman -S go dotnet-sdk zig
# Node.js: use nvm (see the Node section below) or `sudo pacman -S nodejs npm`

git clone <this-repo> ~/.config/nvim
nvim   # lazy.nvim will bootstrap and install plugins on first launch
```

## Quick start (macOS)

If you have Homebrew, the following one block installs everything most users will want:

```bash
# Required
brew install neovim git ripgrep fd tree-sitter-cli

# Recommended
brew install lazygit
brew install --cask font-jetbrains-mono-nerd-font   # any Nerd Font works

# Per-language (install only what you use)
brew install go                 # Go LSP (gopls)
brew install nvm                # Node.js manager — see Node section below
brew install --cask dotnet-sdk  # C# (roslyn, csharpier, netcoredbg)
brew install zig                # Zig toolchain (zls is installed via Mason)

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
| **Neovim ≥ 0.12** | Uses `vim.lsp.config()` / `vim.lsp.enable()`, `vim.diagnostic.jump`; required by `nvim-treesitter` `main` and `roslyn.nvim` | `pacman -S neovim` / `brew install neovim` |
| **git** | `lazy.nvim` clones plugins, Mason clones some registries | `pacman -S git` / `brew install git` |
| **C compiler + `make`** | Tree-sitter parsers and LuaSnip's `jsregexp` are built from source | Arch: `pacman -S base-devel`; macOS: `xcode-select --install` |
| **`tree-sitter-cli` ≥ 0.26.1** | Required by `nvim-treesitter` v1.0 (`main` branch) to install/update parsers | `pacman -S tree-sitter-cli` / `brew install tree-sitter-cli` |
| **`ripgrep`** | Used by `telescope.live_grep` (`<leader>fg`) | `pacman -S ripgrep` / `brew install ripgrep` |
| **A Nerd Font** | Icons in Neo-tree, Lualine, Alpha dashboard, etc. | `pacman -S ttf-nerd-fonts-symbols` / `brew install --cask font-jetbrains-mono-nerd-font` (or any other) — then set your terminal to use it |

### Recommended

| Tool | Why | Install |
|---|---|---|
| **`fd`** | Faster file finding for `telescope.find_files` (`<leader>ff`) | `pacman -S fd` / `brew install fd` |
| **`lazygit`** | Bound to `<leader>tg` (opens lazygit in a floating terminal) | `pacman -S lazygit` / `brew install lazygit` |
| **Clipboard tool** (Linux only) | System clipboard for `<leader>y` / `<leader>p` (`"+` register) | Wayland: `pacman -S wl-clipboard`; X11: `pacman -S xclip`. macOS has this built in |

### Per-language

You only need these for the languages you actually edit. The Mason-installed tools (`prettier`, `vtsls`, `csharpier`, etc.) all run on top of these runtimes.

#### JavaScript / TypeScript / Prisma

Requires **Node.js + npm** so Mason can install:

- `vtsls` — TypeScript/JavaScript LSP
- `prettierd` — daemonised Prettier, run by conform on save
- `eslint` (`vscode-eslint-language-server`) — ESLint diagnostics + fix-all on save (only activates in projects that have an ESLint config)
- `prismals` — Prisma LSP, which also formats `.prisma` files

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

#### Zig

```bash
brew install zig
```

Mason installs `zls` (the Zig Language Server) automatically. ZLS publishes diagnostics natively, so there's no separate linter wired up. Formatting on save runs `zig fmt --stdin` via conform's built-in `zigfmt` formatter, which means **`zig` must be on `PATH`** for format-on-save to work. ZLS settings (inlay hints, build-on-save, etc.) live in `lua/lsp/servers.lua`.

#### Lua

Mason installs `lua_ls` and `stylua`. No system dependency. [`lazydev.nvim`](https://github.com/folke/lazydev.nvim) provides Neovim API / plugin types to `lua_ls` when editing Lua files.

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
  panel.lua                 bottom panel (Ctrl+`): sidebar + terminal / debug views
  terminal-tabs.lua         terminal view: tabbed terminals
  debug-console.lua         debug view: debug output + step buttons
  dotnet.lua                run / debug .NET projects (Neo-tree right-click)
  terminal-maximize.lua     toggle full-size for terminal splits
```

## Keybindings

Leader is `<Space>`. A few highlights:

| Keys | Action |
|---|---|
| `<leader>ff` / `<leader>fg` | Find files / live grep (Telescope) |
| `<leader>fa` | Live grep with args (regex, glob, …) |
| `<leader>nn` / `<leader>nf` | Toggle Neo-tree / reveal current file |
| `<leader>a` / `<leader>h` | Harpoon: add / open menu |
| `<A-j>` `<A-k>` `<A-l>` `<A-n>` | Jump to Harpoon files 1–4 |
| `<leader>gs` / `<leader>gd` | Fugitive: status / diff split |
| `<leader>gh` / `<leader>gb` | Gitsigns: preview hunk / toggle blame |
| `` <C-`> `` | Toggle the bottom panel (terminal tabs / debug console) |
| `<leader>tf` / `<leader>tg` | Toggleterm: float / lazygit |
| `<leader>qf` | Toggle quickfix list (`dd` to delete an item) |
| `<leader>cp` | Copy the current buffer's absolute path |
| `gcc` / `gc{motion}` | Toggle comments (built into Neovim) |
| `<leader>f` | Format buffer (conform.nvim) |
| `<leader>l*` | LSP family: definition, references, rename, code action, … |
| `<leader>d*` | Debug (nvim-dap) — see Debugging section below |
| `[d` / `]d` | Previous / next diagnostic |
| `K` | Hover documentation |

Full list: `<leader>fk` (Telescope keymaps).

## Debugging (nvim-dap)

Powered by `nvim-dap`; the UI is the debug view of the bottom panel (`lua/debug-console.lua`). Currently only **C# / .NET** is wired up via `netcoredbg` (installed by Mason). Adding more languages is just a matter of adding adapters and configurations in `lua/plugins/dap.lua`.

### .NET workflow

1. Place breakpoints by clicking a line number (or `<leader>db`).
2. Right-click the project folder in Neo-tree → **Debug .NET project**. It builds, then launches under the debugger. (Or `dotnet build` yourself and press `<F5>`.)
3. The bottom panel switches to the debug view (bug icon in its sidebar): all debug output, plus Continue / Pause, Step over / into / out, Restart (rebuilds) and Stop buttons. `<F5>` / `<F10>` / `<F11>` / `<F12>` do the same.
4. `<leader>de` shows the value under the cursor, `<leader>ds` the variables in scope, `<leader>dr` the REPL. Values also show inline as virtual text.

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
:Lazy update        " update plugins and write the new versions to lazy-lock.json
:Lazy restore       " (alternative) roll plugins back to what lazy-lock.json pins
:Mason              " then U to update LSPs/formatters
:TSUpdate           " update Tree-sitter parsers
```

## Troubleshooting

- **`vtsls` / `prettierd` / `eslint` failed to install** — Mason needs `npm` on `PATH`. Install Node (see above). On macOS, the bundled Cursor/VS Code Node is *not* sufficient because it doesn't include `npm`.
- **`tree-sitter` executable not found** — `nvim-treesitter` v1.0 (`main` branch) requires the `tree-sitter-cli` (>= 0.26.1) on `PATH`. Install it with `pacman -S tree-sitter-cli` or `brew install tree-sitter-cli`. Without it, `:TSInstall` / `:TSUpdate` hang without a clear error.
- **Parser errors after upgrading Neovim** — run `:TSUpdate` to rebuild parsers against the new runtime ABI.
- **Icons appear as boxes / `?`** — your terminal isn't using a Nerd Font. Set the font in your terminal settings (iTerm2, WezTerm, Ghostty, etc.).
- **`gopls` not formatting on save** — make sure `go` is on `PATH` for the shell that launched Neovim. Check with `:LspInfo`.
- **`roslyn` failed to install / not found** — Mason needs the Crashdummyy registry to find this package. It's registered in `lua/plugins/lsp-config.lua`; if you're seeing the error, run `:MasonUpdate` once after first launch so the new registry is fetched, then `:MasonInstall roslyn`. Also confirm `dotnet --info` works in your shell.
