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
ln -s $(pwd)/config/tmux ~/.config/

echo "03. linking nvim config directory..."
ln -s $(pwd)/config/nvim ~/.config/

echo "04. linking kitty config directory..."
ln -s $(pwd)/config/kitty ~/.config/

echo "05. linking mpv config directory..."
ln -s $(pwd)/config/mpv ~/.config/

echo "06. backing up existing .bashrc and linking new one..."
BACKUP_FILE="${HOME}/.bashrc.bck"
if [ ! -f "${BACKUP_FILE}" ]; then
    if [ -f ~/.bashrc ]; then
        echo "Creating initial backup of ~/.bashrc to ${BACKUP_FILE}"
        cp ~/.bashrc "${BACKUP_FILE}"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to create initial backup. Aborting."
            exit 1
        fi
    else
        echo "~/.bashrc does not exist. No initial backup created."
    fi
else
    echo "Backup file ${BACKUP_FILE} already exists. Skipping backup."
fi

echo "Linking new .bashrc from $(pwd)/home/.bashrc to ~/.bashrc"
ln -sf "$(pwd)/home/.bashrc" ~/.bashrc
if [ $? -ne 0 ]; then
    echo "Error: Failed to link new .bashrc. Aborting."
    exit 1
fi

echo "done."
