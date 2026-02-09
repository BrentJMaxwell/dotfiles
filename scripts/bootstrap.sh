#!/bin/bash

# ─────────────────────────────────────────────────────────────
#  Dotfiles Bootstrap
#  Interactive setup with rich logging
# ─────────────────────────────────────────────────────────────

set -euo pipefail

# ── Colors & Formatting ──────────────────────────────────────

BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

# ── Logging Helpers ──────────────────────────────────────────

CURRENT_SECTION=""
INDENT="  "
SUMMARY_LINES=()
ERRORS=()

section() {
    CURRENT_SECTION="$1"
    echo ""
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}${BLUE}  $1${RESET}"
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

log_info() {
    echo -e "${INDENT}${DIM}→${RESET} $1"
}

log_ok() {
    echo -e "${INDENT}${GREEN}✅ $1${RESET}"
    SUMMARY_LINES+=("${GREEN}✅ $1${RESET}")
}

log_skip() {
    echo -e "${INDENT}${YELLOW}⏭️  $1${RESET}"
    SUMMARY_LINES+=("${YELLOW}⏭️  $1${RESET}")
}

log_warn() {
    echo -e "${INDENT}${YELLOW}⚠️  $1${RESET}"
}

log_error() {
    echo -e "${INDENT}${RED}❌ $1${RESET}"
    ERRORS+=("$1")
    SUMMARY_LINES+=("${RED}❌ $1${RESET}")
}

log_already() {
    echo -e "${INDENT}${DIM}✔  $1 (already done)${RESET}"
    SUMMARY_LINES+=("${DIM}✔  $1 (already done)${RESET}")
}

# Run a command and report pass/fail
run_step() {
    local description="$1"
    shift
    log_info "$description"
    if "$@" > /dev/null 2>&1; then
        log_ok "$description"
        return 0
    else
        log_error "$description"
        return 1
    fi
}

# ── Diff Helpers ──────────────────────────────────────────────

# Show a colored diff between a home file and its repo counterpart.
# Returns: 0 = files differ (diff shown), 1 = no action needed, 2 = identical (auto-handle)
show_diff_file() {
    local home_path="$1"
    local package="$2"
    local home_full="$HOME/$home_path"
    local repo_full="$DOTFILES_DIR/$package/$home_path"

    # Skip if home file doesn't exist or is already a symlink
    if [ ! -e "$home_full" ] || [ -L "$home_full" ]; then
        return 1
    fi

    # Identical — no prompt needed, but file should be moved for stow
    if diff -q "$home_full" "$repo_full" > /dev/null 2>&1; then
        log_already "~/$home_path matches repo"
        return 2
    fi

    # Files differ — show colored diff
    echo ""
    echo -e "${INDENT}${BOLD}${YELLOW}┌── ~/$home_path ──────────────────────────────────${RESET}"
    echo ""
    git --no-pager diff --no-index --color -- "$home_full" "$repo_full" 2>/dev/null || true
    echo ""
    echo -e "${INDENT}${BOLD}${YELLOW}└──────────────────────────────────────────────────${RESET}"
    return 0
}

# Show a colored diff between a home directory and its repo counterpart.
# Returns: 0 = dirs differ (diff shown), 1 = no action needed, 2 = identical (auto-handle)
show_diff_dir() {
    local home_path="$1"
    local package="$2"
    local home_full="$HOME/$home_path"
    local repo_full="$DOTFILES_DIR/$package/$home_path"

    # Skip if home dir doesn't exist or is already a symlink
    if [ ! -d "$home_full" ] || [ -L "$home_full" ]; then
        return 1
    fi

    # Identical — no prompt needed
    if diff -rq "$home_full" "$repo_full" > /dev/null 2>&1; then
        log_already "~/$home_path/ matches repo"
        return 2
    fi

    # Directories differ — show stat summary then full diff
    echo ""
    echo -e "${INDENT}${BOLD}${YELLOW}┌── ~/$home_path/ (directory) ──────────────────────${RESET}"
    echo ""
    echo -e "${INDENT}${DIM}Changed files:${RESET}"
    git --no-pager diff --no-index --color --stat -- "$home_full" "$repo_full" 2>/dev/null || true
    echo ""
    git --no-pager diff --no-index --color -- "$home_full" "$repo_full" 2>/dev/null || true
    echo ""
    echo -e "${INDENT}${BOLD}${YELLOW}└──────────────────────────────────────────────────${RESET}"
    return 0
}

# ── User Prompts ─────────────────────────────────────────────

ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local hint

    if [[ "$default" == "y" ]]; then
        hint="[Y/n]"
    else
        hint="[y/N]"
    fi

    echo ""
    echo -ne "${INDENT}${MAGENTA}❓ ${prompt} ${hint}: ${RESET}"
    read -r answer
    answer="${answer:-$default}"

    case "$answer" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# ── Banner ───────────────────────────────────────────────────

clear
echo ""
echo -e "${BOLD}${CYAN}"
echo "  ┌──────────────────────────────────────────────┐"
echo "  │                                              │"
echo "  │          🏠  Dotfiles Bootstrap  🏠          │"
echo "  │                                              │"
echo "  │    Symlinks • Packages • Shell • Plugins     │"
echo "  │                                              │"
echo "  └──────────────────────────────────────────────┘"
echo -e "${RESET}"
echo -e "  ${DIM}Run from: $(pwd)${RESET}"
echo -e "  ${DIM}Date:     $(date '+%Y-%m-%d %H:%M')${RESET}"
echo ""

DOTFILES_DIR="$HOME/git/personal/dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup"
BACKED_UP=0

# ─────────────────────────────────────────────────────────────
#  Step 1: Create Directory Structure
# ─────────────────────────────────────────────────────────────

section "📁 Directory Structure"

create_dir() {
    local dir="$1"
    if [ -d "$dir" ]; then
        log_already "Directory $dir"
    else
        if mkdir -p "$dir"; then
            log_ok "Created $dir"
        else
            log_error "Failed to create $dir"
        fi
    fi
}

create_dir ~/git/personal
create_dir ~/git/snx

# ─────────────────────────────────────────────────────────────
#  Step 2: OS Detection & Package Installation
# ─────────────────────────────────────────────────────────────

section "📦 Package Installation"

OS="$(uname -s)"
DETECTED_OS="Unknown"
PACKAGES="git zsh stow tmux"

case "${OS}" in
    Linux*)
        if [ -f /etc/arch-release ]; then
            DETECTED_OS="Arch Linux"
            PACKAGES="git zsh stow aws-cli-v2 base-devel tmux"
        elif grep -q Microsoft /proc/version 2>/dev/null; then
            DETECTED_OS="WSL (Ubuntu/Debian)"
            PACKAGES="git zsh stow awscli build-essential tmux"
        else
            DETECTED_OS="Linux (other)"
        fi
        ;;
    Darwin*)
        DETECTED_OS="macOS"
        PACKAGES="git zsh stow awscli ghostty tmux"
        ;;
esac

log_info "Detected OS: ${BOLD}${DETECTED_OS}${RESET}"
log_info "Packages: ${DIM}${PACKAGES}${RESET}"

if ask_yes_no "Install system packages? (${DETECTED_OS})"; then
    case "${OS}" in
        Linux*)
            if [ -f /etc/arch-release ]; then
                if sudo pacman -Syu --noconfirm $PACKAGES; then
                    log_ok "Installed packages via pacman"
                else
                    log_error "Failed to install packages via pacman"
                fi
            elif grep -q Microsoft /proc/version 2>/dev/null; then
                if sudo apt update && sudo apt install -y $PACKAGES; then
                    log_ok "Installed packages via apt"
                else
                    log_error "Failed to install packages via apt"
                fi
            else
                log_warn "Unsupported Linux distro — install packages manually"
            fi
            ;;
        Darwin*)
            if ! command -v brew &> /dev/null; then
                log_info "Installing Homebrew first..."
                if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
                    log_ok "Installed Homebrew"
                else
                    log_error "Failed to install Homebrew"
                fi
            fi
            if brew install $PACKAGES; then
                log_ok "Installed packages via Homebrew"
            else
                log_error "Failed to install packages via Homebrew"
            fi
            ;;
        *)
            log_error "Unknown OS: ${OS}"
            exit 1
            ;;
    esac
else
    log_skip "Package installation (skipped by user)"
fi

# ─────────────────────────────────────────────────────────────
#  Step 3: Oh My Zsh & Plugins
# ─────────────────────────────────────────────────────────────

section "🐚 Oh My Zsh & Plugins"

ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$ZSH_DIR/custom"

# Oh My Zsh
if [ -d "$ZSH_DIR" ]; then
    log_already "Oh My Zsh installed"
else
    log_info "Installing Oh My Zsh..."
    if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
        rm -f "$HOME/.zshrc"
        log_ok "Installed Oh My Zsh"
    else
        log_error "Failed to install Oh My Zsh"
    fi
fi

# zsh-autosuggestions
if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    log_already "zsh-autosuggestions"
else
    log_info "Cloning zsh-autosuggestions..."
    if git clone --quiet https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"; then
        log_ok "Installed zsh-autosuggestions"
    else
        log_error "Failed to install zsh-autosuggestions"
    fi
fi

# zsh-syntax-highlighting
if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    log_already "zsh-syntax-highlighting"
else
    log_info "Cloning zsh-syntax-highlighting..."
    if git clone --quiet https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"; then
        log_ok "Installed zsh-syntax-highlighting"
    else
        log_error "Failed to install zsh-syntax-highlighting"
    fi
fi

# ─────────────────────────────────────────────────────────────
#  Step 4: Tmux Plugin Manager
# ─────────────────────────────────────────────────────────────

section "🖥️  Tmux Plugin Manager"

TPM_DIR="$HOME/.tmux/plugins/tpm"

if [ -d "$TPM_DIR" ]; then
    log_already "Tmux Plugin Manager (TPM)"
else
    log_info "Cloning TPM..."
    if git clone --quiet https://github.com/tmux-plugins/tpm "$TPM_DIR"; then
        log_ok "Installed Tmux Plugin Manager"
    else
        log_error "Failed to install Tmux Plugin Manager"
    fi
fi

if ask_yes_no "Install tmux plugins now?"; then
    if [ -f "$TPM_DIR/bin/install_plugins" ]; then
        if "$TPM_DIR/bin/install_plugins"; then
            log_ok "Installed tmux plugins"
        else
            log_error "Failed to install tmux plugins"
        fi
    else
        log_warn "TPM install script not found — run ${ITALIC}prefix + I${RESET} in tmux manually"
    fi
else
    log_skip "Tmux plugin installation (skipped by user)"
fi

# ─────────────────────────────────────────────────────────────
#  Step 4b: x-cmd
# ─────────────────────────────────────────────────────────────

section "⚡ x-cmd"

X_CMD_ROOT="$HOME/.x-cmd.root"

if [ -f "$X_CMD_ROOT/X" ]; then
    log_already "x-cmd installed at $X_CMD_ROOT"
else
    if ask_yes_no "Install x-cmd?"; then
        if command -v curl &>/dev/null; then
            log_info "Installing x-cmd..."
            if eval "$(curl -fsSL https://get.x-cmd.com)"; then
                log_ok "Installed x-cmd"
            else
                log_error "x-cmd install failed — run manually: ${ITALIC}eval \"\$(curl -fsSL https://get.x-cmd.com)\"${RESET}"
            fi
        else
            log_error "curl required to install x-cmd — install curl first"
        fi
    else
        log_skip "x-cmd installation (skipped by user)"
    fi
fi

# ─────────────────────────────────────────────────────────────
#  Step 5: Backup & Stow Dotfiles
# ─────────────────────────────────────────────────────────────

section "🔗 Symlink Dotfiles (GNU Stow)"

cd "$DOTFILES_DIR"
log_info "Working directory: ${DIM}${DOTFILES_DIR}${RESET}"

# ── File-to-package mappings (format: "home_path|stow_package") ──

FILE_MAPPINGS=(
    ".gitconfig|git"
    ".gitconfig-personal|git"
    ".gitconfig-snx|git"
    ".zshrc|zsh"
    ".ssh/config|ssh"
    ".tmux.conf|tmux"
)

# Directory-to-package mappings (diffed recursively)
DIR_MAPPINGS=(
    ".config/ghostty|ghostty"
    ".aws|aws"
)

STOW_PACKAGES=(git zsh ghostty aws ssh tmux)
REJECTED_PACKAGES=()

# ── Helpers ──

backup_path() {
    local file="$1"
    log_info "Backing up ~/$file → $BACKUP_DIR/$file"
    mkdir -p "$BACKUP_DIR/$(dirname "$file")"
    rm -rf "${BACKUP_DIR:?}/$file"
    mv "$HOME/$file" "$BACKUP_DIR/$file"
    BACKED_UP=1
}

remove_symlink() {
    local file="$1"
    if [ -L "$HOME/$file" ]; then
        rm -f "$HOME/$file"
    fi
}

reject_package() {
    local package="$1"
    if [[ ! " ${REJECTED_PACKAGES[*]:-} " =~ " ${package} " ]]; then
        REJECTED_PACKAGES+=("$package")
    fi
}

# ── Review individual config files ──

log_info "Reviewing config files for changes..."

for entry in "${FILE_MAPPINGS[@]}"; do
    home_path="${entry%%|*}"
    package="${entry##*|}"

    # Clean up existing symlinks from a previous stow run
    remove_symlink "$home_path"

    # Diff and prompt
    diff_result=0
    show_diff_file "$home_path" "$package" || diff_result=$?

    case $diff_result in
        0)  # Files differ — user must approve
            if ask_yes_no "Back up and replace ~/$home_path?"; then
                backup_path "$home_path"
                log_ok "Backed up ~/$home_path"
            else
                log_skip "Kept existing ~/$home_path"
                reject_package "$package"
            fi
            ;;
        2)  # Identical — silently move out of the way for stow
            backup_path "$home_path"
            ;;
        *)  # File doesn't exist or was a symlink — nothing to do
            ;;
    esac
done

# ── Review config directories ──

for entry in "${DIR_MAPPINGS[@]}"; do
    home_path="${entry%%|*}"
    package="${entry##*|}"

    # Clean up existing symlinks
    remove_symlink "$home_path"

    # Diff and prompt
    diff_result=0
    show_diff_dir "$home_path" "$package" || diff_result=$?

    case $diff_result in
        0)  # Directory differs — user must approve
            if ask_yes_no "Back up and replace ~/$home_path/?"; then
                backup_path "$home_path"
                log_ok "Backed up ~/$home_path/"
            else
                log_skip "Kept existing ~/$home_path/"
                reject_package "$package"
            fi
            ;;
        2)  # Identical — silently move for stow
            backup_path "$home_path"
            ;;
        *)  # Doesn't exist or was a symlink — nothing to do
            ;;
    esac
done

if [ "$BACKED_UP" = "1" ]; then
    log_ok "Existing configs backed up to ${BOLD}$BACKUP_DIR${RESET}"
fi

# ── Stow packages (skip rejected) ──

log_info "Stowing dotfile packages..."

for pkg in "${STOW_PACKAGES[@]}"; do
    if [[ " ${REJECTED_PACKAGES[*]:-} " =~ " ${pkg} " ]]; then
        log_warn "Skipping stow for ${BOLD}$pkg${RESET} (changes were declined)"
        continue
    fi
    if stow -t "$HOME" --restow "$pkg" 2>/dev/null; then
        log_ok "Stowed ${BOLD}$pkg${RESET}"
    else
        log_error "Failed to stow ${BOLD}$pkg${RESET}"
    fi
done

# ─────────────────────────────────────────────────────────────
#  Step 6: AWS Config Check
# ─────────────────────────────────────────────────────────────

section "☁️  AWS Configuration"

if [ -f ~/.aws/config ]; then
    log_already "AWS config found"
else
    log_warn "No AWS config found — run ${ITALIC}aws configure${RESET} manually"
fi

# ─────────────────────────────────────────────────────────────
#  Step 7: Default Shell
# ─────────────────────────────────────────────────────────────

section "💻 Default Shell"

ZSH_PATH="$(which zsh 2>/dev/null || true)"

if [ -z "$ZSH_PATH" ]; then
    log_error "zsh not found in PATH — install it first"
elif [ "$SHELL" = "$ZSH_PATH" ]; then
    log_already "Default shell is zsh"
else
    log_info "Current shell: ${DIM}$SHELL${RESET}"
    log_info "Zsh path:      ${DIM}$ZSH_PATH${RESET}"
    if ask_yes_no "Change default shell to zsh?"; then
        if chsh -s "$ZSH_PATH"; then
            log_ok "Default shell changed to zsh"
        else
            log_error "Failed to change shell (you may need to run ${ITALIC}chsh -s $ZSH_PATH${RESET} manually)"
        fi
    else
        log_skip "Shell change (skipped by user)"
    fi
fi

# ─────────────────────────────────────────────────────────────
#  Summary
# ─────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}${CYAN}  📋 Summary${RESET}"
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

for line in "${SUMMARY_LINES[@]}"; do
    echo -e "${INDENT}$line"
done

echo ""

# Backup location
if [ "$BACKED_UP" = "1" ]; then
    echo -e "${INDENT}${BOLD}${YELLOW}📦 Backup location: ${RESET}${YELLOW}$BACKUP_DIR${RESET}"
    echo ""
fi

# Error count
if [ ${#ERRORS[@]} -gt 0 ]; then
    echo -e "${INDENT}${RED}${BOLD}${#ERRORS[@]} error(s) occurred.${RESET} Review the log above for details."
else
    echo -e "${INDENT}${GREEN}${BOLD}All steps completed successfully!${RESET}"
fi

echo ""
echo -e "${INDENT}${DIM}Restart your terminal to apply all changes.${RESET}"
echo ""
