eval "$(/opt/homebrew/bin/brew shellenv)"

# XDG BASE DIRECTORY
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$XDG_CONFIG_HOME/local/share"
export XDG_CACHE_HOME="$XDG_CONFIG_HOME/cache"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

export GIT_CONFIG_GLOBAL="$XDG_CONFIG_HOME/git/.gitconfig"

export DROPBOX_DIR="$HOME/Library/CloudStorage/Dropbox/"
export TOOLBOX_BCK_DIR="$DROPBOX_DIR/toolbox/bck"
eval "$(/opt/homebrew/bin/mise activate zsh --shims)"

