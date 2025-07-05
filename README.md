# Dotfiles

Configuration files that I use with Arch. Run the `setup.sh` file to link files and directories to proper place.

## 1. neovim

All you needed to upscale your vanilla neovim to the Gigachad neovim

### Plugins

- treesitter
- fugitive
- harpoon man
- telescope
- undo tree
- rose pine
- lsp zero
- conform nvim
- friendly snippets
- mason
- copilot
- lazy nvim
- vim be good

### Quick Peek

| Shortcut | Description           |
| -------- | --------------------- |
| ⎵pv      | :Ex                   |
| ⎵gs      | git status            |
| ⎵a       | add to harpoon        |
| Ctrl e   | harpoon quick menu    |
| ⎵pf      | project find          |
| Ctrl p   | git file find         |
| ⎵ps      | project search (grep) |
| ⎵u       | undo tree             |

### Tips

run `:checkhealth` and install dependencies if possible. In my case, I installed **ripgrep** and **fd**.

### Source of Information

Watch this beautiful [vim rc](https://youtu.be/w7i4amO_zaE) video from [@ThePrimeagen](https://github.com/ThePrimeagen).
[init.lua](https://github.com/ThePrimeagen/init.lua)

## 2. tmux + tmux sessionizer

`tmuxs` -> launches a fuzzy find window with the directories you've configured in tmux-sessionizer file in `~/.local/bin/tmux-sessionizer`.
When you select an option, a new tmux session is opened for that directory. Use `ctrl+b+f` to launch the fuzzy find window - for more information check the file.

## 3. bashrc

Just a copy of bashrc. Please don't ask me where's the macos and arch rc's are.

## 4. kitty

kittens.
