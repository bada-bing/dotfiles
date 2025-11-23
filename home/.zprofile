eval "$(/opt/homebrew/bin/brew shellenv)"

# XDG BASE DIRECTORY
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$XDG_CONFIG_HOME/local/share"
export XDG_CACHE_HOME="$XDG_CONFIG_HOME/cache"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

export GIT_CONFIG_GLOBAL="$XDG_CONFIG_HOME/git/.gitconfig"

export ICLOUD_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
export DOCUMENTS_DIR="$HOME/Documents"
export ENV_DIR="$DOCUMENTS_DIR/toolbox/env"

# eval "$(/opt/homebrew/bin/mise activate zsh --shims)"

# Added by OrbStack: command-line tools and integration
source ~/.orbstack/shell/init.zsh 2>/dev/null || :