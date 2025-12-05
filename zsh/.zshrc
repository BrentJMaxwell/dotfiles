export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster" # or whatever you prefer
plugins=(git aws docker) # Add standard plugins

source $ZSH/oh-my-zsh.sh

# Custom Aliases
alias g="git"
# alias k="kubectl"

# Ensure local bin is in path
export PATH="$HOME/.local/bin:$PATH"
