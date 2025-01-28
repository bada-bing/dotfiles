# TEXT EDITORS
export EDITOR="vim"
# export EDITOR="code -w" # -w is to wait untill you are done with editing
export VISUAL="vim"

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
source $ENV_DIR/work.aliases

# SSH VERSION WHICH SUPPORTS YUBIKEYS
export PATH=$(brew --prefix openssh)/bin:$PATH
export GOPATH=/Users/miki/src/go

# PROMPT
source $ZDOTDIR/.prompt.zsh

# Mise - Runmtime/Package Manager
eval "$(/opt/homebrew/bin/mise activate zsh)"

# The zsh-vi-mode plugin will auto execute this zvm_config function
zvm_config() {
  # Retrieve default cursor styles
  #   local ncur=$(zvm_cursor_style $ZVM_NORMAL_MODE_CURSOR)
  local ncur=$(zvm_cursor_style $ZVM_CURSOR_BLINKING_BLOCK)
  local icur=$(zvm_cursor_style $ZVM_CURSOR_BLINKING_BEAM)

  # Append your custom color for your cursor
  ZVM_INSERT_MODE_CURSOR=$icur'\e\e]12;#FF6961\a'
  ZVM_NORMAL_MODE_CURSOR=$ncur'\e\e]12;#77DD77\a'

  # Always starting with insert mode for each command line
  ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT
}

# LOAD PLUGINS
# You need to clone them first
# git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/plugins/zsh-syntax-highlighting
# git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/plugins/zsh-autosuggestions
source $ZDOTDIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $ZDOTDIR/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source $ZDOTDIR/plugins/zsh-vi-mode/zsh-vi-mode.zsh # better alternative to the default zsh's vi mode

function zsh_autosuggest_bindings() {
    bindkey '^j' backward-word
    bindkey '^f' forward-word
    bindkey '^g' autosuggest-accept
    
    # TODO the arrow keys do not work reliably and have no patience to investigate now
    # Bind the right arrow key to accept the current suggestion
    # bindkey '^[[1;9' autosuggest-accept # cmd ->
    # bindkey '^[[1;5C' forward-word # ctrl ->
    # bindkey '^[[C' forward-word # ->
    # bindkey '^[[1;6D' backward-word
    # bindkey '^[[D' backward-word
}
zvm_after_init_commands+=(zsh_autosuggest_bindings)

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
export PATH="~/src/scripts:/opt/homebrew/bin:$GOPATH/bin:$HOME/.cargo/bin:$PATH"

# GCLOUD & KUBECTL
SE_GKE_GCLOUD_AUTH_PLUGIN=True

FZF_CONFIG=$XDG_CONFIG_HOME/fzf/fzf.zsh

[ -f "$FZF_CONFIG" ] && source "$FZF_CONFIG"
source ~/src/scripts/node/pick_npm_script.sh
source ~/src/scripts/git/checkout_branch.sh

eval "$(zoxide init zsh)"

# yazi
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}
