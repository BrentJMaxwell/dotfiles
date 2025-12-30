# Dotfiles

Personal dotfiles managed with GNU Stow.

## Quick Start

```bash
git clone https://github.com/yourusername/dotfiles.git ~/git/personal/dotfiles
cd ~/git/personal/dotfiles
./scripts/bootstrap.sh
```

## What's Included

### Terminal & Shell
- **Zsh** - Shell configuration with Oh My Zsh
  - Custom plugins: zsh-autosuggestions, zsh-syntax-highlighting
- **Tmux** - Terminal multiplexer configuration
  - TPM (Tmux Plugin Manager) auto-installation
  - Catppuccin theme (macchiato flavor)
  - Mouse support enabled
  - Plugins: tmux-sensible, catppuccin/tmux
- **Ghostty** - Terminal emulator configuration
  - Catppuccin themes included

### Development Tools
- **Git** - Version control configuration
  - Personal and work (snx) profiles
- **AWS CLI** - AWS configuration structure
- **SSH** - SSH client configuration

## Directory Structure

```
dotfiles/
├── aws/          # AWS CLI configuration
├── git/          # Git configuration files
├── ghostty/      # Ghostty terminal config
├── oh-my-zsh/    # Oh My Zsh framework
├── scripts/      # Installation scripts
│   └── bootstrap.sh
├── ssh/          # SSH configuration
├── tmux/         # Tmux configuration
│   └── .tmux.conf
└── zsh/          # Zsh configuration
```

## Manual Steps

After running the bootstrap script:

1. **AWS Configuration**: Run `aws configure` if needed
2. **Tmux Plugins**: If automatic installation fails, press `Ctrl+b` then `I` inside tmux to install plugins
3. **Shell Change**: Restart your terminal after installation

## Tmux Configuration

The tmux setup includes:
- **TPM (Tmux Plugin Manager)** - Automatically installed at `~/.tmux/plugins/tpm`
- **Key Bindings**: 
  - `Ctrl+b r` - Reload tmux configuration
  - `Ctrl+b I` - Install plugins (TPM)
- **Features**:
  - Mouse support
  - 256 color support
  - Status bar on top
  - Catppuccin theme with CPU, battery, session, and uptime modules

## Updating

To update your configuration:

```bash
cd ~/git/personal/dotfiles
git pull
./scripts/bootstrap.sh
```

Existing configurations are backed up to `~/.dotfiles-backup-{timestamp}/` before stowing new ones.
