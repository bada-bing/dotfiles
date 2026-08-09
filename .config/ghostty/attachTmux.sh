#!/bin/bash

eval "$(/opt/homebrew/bin/brew shellenv)"

export TOOLBOX_DIR=~/Developer/toolbox
export PATH="/opt/homebrew/bin:$PATH"

# A fresh Ghostty surface is never inside a tmux client, even when Ghostty was
# launched from a tmux pane and inherited these — scrub them so the session
# script attaches instead of trying to switch the launching client.
unset TMUX TMUX_PANE

bash "$TOOLBOX_DIR/scripts/tmux/default_session.sh"