NOTE: do not use on windows, unless it's wsl

LazyVim requires the following be installed on the system:
- a Nerd Font[https://www.nerdfonts.com/]
- lazygit[https://github.com/jesseduffield/lazygit]
- install Homebrew[https://brew.sh/] (for convenience)
  - $ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
- $ brew install ripgrep #(this helps with fuzzy find searching)
- $ apt install fd-find
- $ ln -s $(which fdfind) ~/.local/bin/fd #(if this fails then you don't need to do it)
- $ sudo apt update && sudo apt install build-essential #(this command adds c compiler, aka the gcc command you need)
- $ brew install neovim
 
Language support tested
- typescript
  - requires node, ts-node, npx tsx
