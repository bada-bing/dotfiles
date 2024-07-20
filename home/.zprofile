eval "$(/opt/homebrew/bin/brew shellenv)"

# XDG BASE DIRECTORY
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$XDG_CONFIG_HOME/local/share"
export XDG_CACHE_HOME="$XDG_CONFIG_HOME/cache"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

export GIT_CONFIG_GLOBAL="$XDG_CONFIG_HOME/git/.gitconfig"

eval "$(/opt/homebrew/bin/mise activate zsh --shims)"

