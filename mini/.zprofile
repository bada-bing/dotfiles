
eval "$(/opt/homebrew/bin/brew shellenv)"

# mise shims, so a login shell, a script and proc reach the tools of the mise config
eval "$(/opt/homebrew/bin/mise activate zsh --shims)"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
