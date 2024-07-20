# Taken from https://sampo.website/blog/en/2021/zsh/

# CONFIGURE THE VERSION CONTROL SYSTEM INFORMATION
# setup git information
autoload -Uz vcs_info
precmd_functions+=( vcs_info )
setopt prompt_subst

zstyle ':vcs_info:git:*' formats '%F{5}(%b%u)%f ' # %b: branch ; %u: unstaged changes
# this makes %u work, but also the prompt is clearly slower in git dirs when this is on
zstyle ':vcs_info:*' check-for-changes true
# what string to use for %u when there are unstaged changes
zstyle ':vcs_info:*' unstagedstr '*'
# vcs_info supports multiple version control systems, but I need just git
zstyle ':vcs_info:*' enable git

# DEFINE THE ACTUAL PROMPT

# Explaining prompt:
#
# %B / %F{n}: begin bold / color
# %b / %f: end bold / color
# %n~: display n latest directories of current directory
# %#: display a '%' (or '#' when root)
# %(..): conditional expression (see docs)
# %?: exit code of last process
# %n@%m: user@host

PROMPT='%B${vcs_info_msg_0_}%F{12}%2~%f %# %b'
# rprompt is located on the right side of the terminal
RPROMPT='%(?..%F{red}(%?%) %f)%n@%m'