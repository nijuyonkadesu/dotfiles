echo -n "are you in the root of the dotfiles repo? (y/n): "
read answer

if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
    echo "aborting. please run the script from the root of the dotfiles repo."
    echo "this script creates system links for relevant file/directory to your home directory."
    exit 1
fi

echo "01. creating symlink for tmux-sessionizer..."
ln -s $(pwd)/bin/tmux-sessionizer ~/.local/bin/tmux-sessionizer

echo "02. linking tmux config directory..."
ln -s $(pwd)/config/tmux ~/.config/tmux

echo "03. linking nvim config directory..."
ln -s $(pwd)/config/nvim ~/.config/

echo "04. linking kitty config directory..."
ln -s $(pwd)/config/kitty ~/.config/

echo "05. linking mpv config directory..."
ln -s $(pwd)/config/mpv ~/.config/

echo "06. backing up existing .bashrc and linking new one..."
cp ~/.bashrc ~/.bashrc.bck && \
    ln -sf $(pwd)/home/.bashrc ~/.bashrc

echo "done."

