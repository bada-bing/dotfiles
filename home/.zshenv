# Read by every zsh, login or not, before any other startup file. ZDOTDIR has
# to be set here rather than in .zprofile: a shell that inherits ZDOTDIR looks
# for .zprofile under it, so setting it there means every nested login shell
# skips .zprofile entirely - taking every PATH entry and export with it.
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
