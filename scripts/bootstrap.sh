#!/bin/bash

# 1. Create the specific Git directories
echo "Creating git directories..."
mkdir -p ~/git/personal
mkdir -p ~/git/snx

# 2. OS Detection & Package Installation (optional)
if [ "${INSTALL_PACKAGES:-0}" = "1" ]; then
    OS="$(uname -s)"
    case "${OS}" in
        Linux*)     
            if [ -f /etc/arch-release ]; then
                echo "Detected Arch Linux"
                sudo pacman -Syu --noconfirm git zsh stow aws-cli-v2 base-devel tmux
                # Install yay or paru if needed for AUR packages like ghostty
            elif grep -q Microsoft /proc/version; then
                echo "Detected WSL"
                sudo apt update && sudo apt install -y git zsh stow awscli build-essential tmux
            fi
            ;;
        Darwin*)    
            echo "Detected macOS"
            # Check for Homebrew
            if ! command -v brew &> /dev/null; then
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install git zsh stow awscli ghostty tmux
            ;;
        *)          
            echo "Unknown OS: ${OS}" 
            exit 1
            ;;
    esac
else
    echo "Skipping package installation (set INSTALL_PACKAGES=1 to enable)."
fi

# 3. Install Oh My Zsh (if not present)
ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$ZSH_DIR/custom"
if [ ! -d "$ZSH_DIR" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    rm -f "$HOME/.zshrc"
fi

# 3.a. Install Custom Plugins (Optional but recommended)
# Example: zsh-autosuggestions and syntax-highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    echo "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    echo "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# 3.b. Install Tmux Plugin Manager (TPM)
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    echo "Installing Tmux Plugin Manager (TPM)..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

# 4. Stow (Symlink) Configs
echo "Stowing dotfiles..."
cd ~/git/personal/dotfiles

BACKUP_DIR="$HOME/.dotfiles-backup"
BACKED_UP=0

# Function to backup existing files before stowing
backup_if_exists() {
    local file="$1"
    if [ -e "$HOME/$file" ] && [ ! -L "$HOME/$file" ]; then
        echo "Backing up existing $file..."
        mkdir -p "$BACKUP_DIR/$(dirname "$file")"
        rm -rf "$BACKUP_DIR/$file"
        mv "$HOME/$file" "$BACKUP_DIR/$file"
        BACKED_UP=1
    elif [ -L "$HOME/$file" ]; then
        # Remove existing symlinks (likely from previous stow)
        rm -f "$HOME/$file"
    fi
}

# Backup existing configs that would conflict with stow
# Git configs
backup_if_exists ".gitconfig"
backup_if_exists ".gitconfig-personal"
backup_if_exists ".gitconfig-snx"

# Zsh config
backup_if_exists ".zshrc"

# Ghostty config
backup_if_exists ".config/ghostty"

# AWS config
backup_if_exists ".aws"

# SSH config (only the config file, not keys)
backup_if_exists ".ssh/config"

# Tmux config
backup_if_exists ".tmux.conf"

if [ "$BACKED_UP" = "1" ]; then
    echo "📦 Existing configs backed up to: $BACKUP_DIR"
fi

# Stow each package (target home directory explicitly)
stow -t "$HOME" --restow git
stow -t "$HOME" --restow zsh
stow -t "$HOME" --restow ghostty
stow -t "$HOME" --restow aws
stow -t "$HOME" --restow ssh
stow -t "$HOME" --restow tmux

# 5. AWS Setup (Optional Helper)
if [ ! -f ~/.aws/config ]; then
    echo "AWS config not found. Please run 'aws configure' manually."
fi

# 5.a. Tmux Plugin Installation
if [ "${INSTALL_TPM_PLUGINS:-0}" = "1" ]; then
    if [ -f "$TPM_DIR/bin/install_plugins" ]; then
        echo "Installing tmux plugins..."
        "$TPM_DIR/bin/install_plugins"
    else
        echo "⚠️  Please install tmux plugins manually: prefix + I (usually Ctrl+b, then I) in tmux"
    fi
else
    echo "Skipping tmux plugin install (set INSTALL_TPM_PLUGINS=1 to enable)."
fi

# 6. Change Shell to Zsh
# Check if the current shell is already zsh
if [ "${CHANGE_SHELL:-0}" = "1" ]; then
    if [ "$SHELL" != "$(which zsh)" ]; then
        echo "Changing default shell to zsh..."
        # This will prompt for password
        chsh -s $(which zsh)
    else
        echo "Already using zsh."
    fi
else
    echo "Skipping shell change (set CHANGE_SHELL=1 to enable)."
fi

echo "✅ Dotfiles setup complete! Please restart your terminal."
