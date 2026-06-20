eval "$(/opt/homebrew/bin/brew shellenv)"

# XDG BASE DIRECTORY
export XDG_CONFIG_HOME="$HOME/.config" # alternative would be `~/Library/ApplicationSupport`
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# ESSENTIAL DIRECTORIES
export ICLOUD_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
export DOCUMENTS_DIR="$HOME/Documents"
export TOOLBOX_DIR="$HOME/Developer/toolbox"
export SCRIPTS_DIR="$TOOLBOX_DIR/scripts"
export ENV_DIR="$TOOLBOX_DIR/private/env"
export WA_1_CONFIG_DIR="$ENV_DIR/wa-1"

# CONFIGURATION LOCATIONS
export GIT_CONFIG_GLOBAL="$XDG_CONFIG_HOME/git/.gitconfig"

# Added by OrbStack: command-line tools and integration
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
# Added by Obsidian
export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"
