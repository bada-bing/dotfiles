# TEXT EDITORS
export EDITOR="vim"
export VISUAL="code"

# VI Mode
bindkey -v
export KEYTIMEOUT=1

# ZSH ENVIRONMENT VARIABLES
# export HISTFILE="$ZDOTDIR/.zhistory" # For some reason does not work as expected
export HISTSIZE=2000  # Maximum events for internal memory
export SAVEHIST=10000 # Maximum events in history file

# ZSH OPTIONS
setopt HIST_SAVE_NO_DUPS # Do not write duplicate event to the history file

### History Search Navigation
# In case it does not work, check this page: https://unix.stackexchange.com/questions/97843/how-can-i-search-history-with-text-already-entered-at-the-prompt-in-zsh
bindkey "^[[A" history-beginning-search-backward # I tried default macros like "$key[Up]" but it did not work on MacOS
bindkey "^[[B" history-beginning-search-forward

### Directory Stack
setopt AUTO_PUSHD  # Push the current dir visited on the stack
setopt PUSHD_IGNORE_DUPS # Do not store duplicates in the stack
setopt PUSHD_SILENT # Do not print the directory stack after pushd or popd

setopt appendhistory

# ALIASES
alias d='dirs -v'
for index ({1..9}) alias "$index"="cd +${index}"; unset index
source $XDG_CONFIG_HOME/.aliases
source $LOCAL_ENV_DIR/work.aliases

# SSH VERSION WHICH SUPPORTS YUBIKEYS
export PATH=$(brew --prefix openssh)/bin:$PATH

# PROMPT
source $ZDOTDIR/.prompt.zsh

# Mise - Runmtime/Package Manager
eval "$(/opt/homebrew/bin/mise activate zsh)"

# LOAD PLUGINS
# You need to clone them first
# git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/plugins/zsh-syntax-highlighting
# git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/plugins/zsh-autosuggestions
source $ZDOTDIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $ZDOTDIR/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# Bind the right arrow key to accept the current suggestion
bindkey '^[[1;9' autosuggest-accept # cmd ->

# Bind the tab key to accept the current suggestion completely
bindkey '^[[C' forward-word # ->
bindkey '^[[D' backward-word


# The next line updates PATH for the Google Cloud SDK.
# if [ -f '~/google-cloud-sdk/path.zsh.inc' ]; then . '~/google-cloud-sdk/path.zsh.inc'; fi
source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"

# # The next line enables shell coømmand completion for gcloud.
# if [ -f '~/google-cloud-sdk/completion.zsh.inc' ]; then . '~/google-cloud-sdk/completion.zsh.inc'; fi
source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"

# FZF & FD Commands (does not work properly on Mac)
export FZF_DEFAULT_COMMAND="fd ." #  "." represents the "catch all" pattern (basically if I am not mistaken, it searches the current directory)
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd -t d . $HOME"

# export PATH="/opt/homebrew/opt/python@3.10/bin:$PATH"
export PATH="~/src/scripts:$PATH"
export PATH="~/src/scripts/tmux:$PATH"
export PATH="/opt/homebrew/bin:$PATH"

export USE_GKE_GCLOUD_AUTH_PLUGIN=True

eval $(thefuck --alias)

# GCLOUD & KUBECTL
SE_GKE_GCLOUD_AUTH_PLUGIN=True

FZF_CONFIG=$XDG_CONFIG_HOME/fzf/fzf.zsh

[ -f "$FZF_CONFIG" ] && source "$FZF_CONFIG"
source ~/src/scripts/node/pick_npm_script.sh
source ~/src/scripts/git/checkout_branch.sh
