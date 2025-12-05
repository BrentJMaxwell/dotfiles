#!/bin/bash

# 1. Create the specific Git directories
echo "Creating git directories..."
mkdir -p ~/git/personal
mkdir -p ~/git/snx

# 2. OS Detection & Package Installation
OS="$(uname -s)"
case "${OS}" in
    Linux*)     
        if [ -f /etc/arch-release ]; then
            echo "Detected Arch Linux"
            sudo pacman -Syu --noconfirm git zsh stow aws-cli base-devel
            # Install yay or paru if needed for AUR packages like ghostty
        elif grep -q Microsoft /proc/version; then
            echo "Detected WSL"
            sudo apt update && sudo apt install -y git zsh stow awscli build-essential
        fi
        ;;
    Darwin*)    
        echo "Detected macOS"
        # Check for Homebrew
        if ! command -v brew &> /dev/null; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install git zsh stow awscli ghostty
        ;;
    *)          
        echo "Unknown OS: ${OS}" 
        exit 1
        ;;
esac

# 3. Install Oh My Zsh (if not present)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    # Remove the auto-generated .zshrc so Stow can replace it
    rm "$HOME/.zshrc" 
fi

# 4. Stow (Symlink) Configs
echo "Stowing dotfiles..."
cd ~/dotfiles

# Loop through directories and stow them
# This symlinks everything inside the folder to $HOME
stow git
stow zsh
stow ghostty
stow aws
stow ssh

# 5. AWS Setup (Optional Helper)
if [ ! -f ~/.aws/credentials ]; then
    echo "AWS Credentials not found. Please run 'aws configure' manually."
fi

echo "✅ Dotfiles setup complete! Please restart your terminal."
