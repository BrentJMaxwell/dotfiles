# Dotfiles

Personal dotfiles managed with GNU Stow.

## Before Cloning (New Machine)

1. **Add SSH keys**: Place your personal key at `~/.ssh/id_ed25519_personal` (chmod 600).
2. **Optional SSH alias**: Add this to `~/.ssh/config` so the clone uses your personal key:

```sshconfig
Host github-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_personal
    IdentitiesOnly yes
```

3. **Clone via alias**:

```bash
git clone git@github-personal:BrentJMaxwell/dotfiles.git ~/git/personal/dotfiles
```

After cloning, run the bootstrap script below.

## Quick Start

```bash
cd ~/git/personal/dotfiles
./scripts/bootstrap.sh
```

Deterministic re-run (no package installs, no tmux plugin install, no shell change):

```bash
./scripts/bootstrap.sh
```

Optional one-time installs:

```bash
INSTALL_PACKAGES=1 INSTALL_TPM_PLUGINS=1 CHANGE_SHELL=1 ./scripts/bootstrap.sh
```

Env var behavior:
- `INSTALL_PACKAGES=1` runs OS package installs/updates
- `INSTALL_TPM_PLUGINS=1` installs tmux plugins via TPM
- `CHANGE_SHELL=1` changes the default shell to zsh

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
2. **Tmux Plugins**: If you skipped `INSTALL_TPM_PLUGINS=1` or it fails, press `Ctrl+b` then `I` inside tmux to install plugins
3. **Shell Change**: If you used `CHANGE_SHELL=1`, restart your terminal after installation
4. **Optional flags**: Re-run with `INSTALL_PACKAGES=1`, `INSTALL_TPM_PLUGINS=1`, or `CHANGE_SHELL=1` when you explicitly want those actions

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

Existing configurations are backed up to `~/.dotfiles-backup/` before stowing new ones.
