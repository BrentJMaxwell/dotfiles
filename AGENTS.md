# Dotfiles

> Personal dotfiles managed with GNU Stow, bootstrapped via an interactive shell script.

## Project Overview

This repository contains personal configuration files ("dotfiles") for terminal
tools, shell, Git, AWS, and SSH. Files are symlinked into `$HOME` using
[GNU Stow](https://www.gnu.org/software/stow/). The single entry point is
`scripts/bootstrap.sh`, which handles OS detection, package installation,
backups, and Stow operations.

## Directory Structure

```
dotfiles/
├── aws/          # AWS CLI config (Stow package → ~/.aws/)
├── git/          # Git config (Stow package → ~/.gitconfig, etc.)
├── ghostty/      # Ghostty terminal config (Stow package → ~/.config/ghostty/)
├── oh-my-zsh/    # Oh My Zsh framework (cloned, NOT a Stow package)
├── scripts/      # Installation & bootstrap scripts
│   └── bootstrap.sh
├── ssh/          # SSH client config (Stow package → ~/.ssh/)
├── tmux/         # Tmux config (Stow package → ~/.tmux.conf)
└── zsh/          # Zsh config (Stow package → ~/.zshrc)
```

### Key concept: GNU Stow packages

Each top-level directory (except `oh-my-zsh/` and `scripts/`) is a **Stow
package**. The internal directory structure mirrors `$HOME`. Running
`stow <package>` from the repo root creates symlinks in `$HOME` pointing back
to the files in the package directory.

Example: `git/.gitconfig` becomes `~/.gitconfig` via symlink.

**Do not** reorganise package directory structures without understanding how Stow
resolves target paths.

## Commands

```bash
# Safe idempotent run (no installs, no system changes)
./scripts/bootstrap.sh

# Full setup on a new machine
INSTALL_PACKAGES=1 INSTALL_TPM_PLUGINS=1 CHANGE_SHELL=1 ./scripts/bootstrap.sh
```

### Environment variables

| Variable              | Effect                                    |
|-----------------------|-------------------------------------------|
| `INSTALL_PACKAGES=1`  | Install/update OS packages via pacman/apt/brew |
| `INSTALL_TPM_PLUGINS=1` | Install tmux plugins via TPM            |
| `CHANGE_SHELL=1`      | Change the default shell to zsh           |

## Code Style

### Shell scripts

- Shebang: `#!/bin/bash` (not `#!/usr/bin/env bash` — this repo uses `/bin/bash`)
- Use `set -euo pipefail` at the top of scripts
- Quote all variable expansions: `"${var}"`, `"$1"`
- Use `[[ ]]` for conditionals (not `[ ]`)
- Use `snake_case` for variables and function names
- Functions: `name() {` style (no `function` keyword)
- Add comments for non-obvious logic; use section headers with `# ── Title ──`

### Configuration files

- Follow the native format/style of each tool (INI for gitconfig, shell syntax for zsh, etc.)
- Theme preference: **Catppuccin Macchiato** when a theme choice exists
- Font preference: **JetBrains Mono** where applicable
- Include inline comments explaining non-default settings

## Supported Platforms

The bootstrap script supports three platforms. Changes must work on all:

- **Arch Linux** — `pacman` for packages
- **WSL / Debian / Ubuntu** — `apt` for packages
- **macOS** — `brew` for packages

## Safety & Boundaries

### NEVER

- Expose, log, or commit secrets (SSH private keys, AWS credentials, tokens, API keys)
- Modify files under `aws/.aws/cli/cache/` or `aws/.aws/sso/cache/`
- Run `stow` or `stow --restow` without explicit user confirmation
- Install packages, change the default shell, or alter system state without asking
- Delete or overwrite files in `~/.dotfiles-backup/`
- Push directly to `main` without review

### ALWAYS

- Understand the GNU Stow symlink model before changing package directory structures
- Back up existing config files before replacing or modifying them
- Verify that `scripts/bootstrap.sh` runs cleanly (no env vars) after changes
- Keep changes cross-platform — test logic against Arch, WSL/Debian, and macOS paths
- Respect existing section structure and logging helpers in `bootstrap.sh`

## Git Workflow

- Primary branch: `main`
- Commit messages: short imperative summary (e.g., "Add ghostty shader config")
- One logical change per commit
- Pull before pushing: the repo may be updated from multiple machines

## Testing

There is no automated test suite. Validation is manual:

1. Run `./scripts/bootstrap.sh` with no env vars — should complete without errors
2. Verify symlinks are correct: `ls -la ~/.gitconfig ~/.zshrc ~/.tmux.conf`
3. Open a new terminal session and confirm shell/prompt works
4. For platform-specific changes, test on the target OS or review the conditional logic carefully
