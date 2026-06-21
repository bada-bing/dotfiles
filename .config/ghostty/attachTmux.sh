#!/bin/bash

eval "$(/opt/homebrew/bin/brew shellenv)"

TMUX=/opt/homebrew/bin/tmux
SESSION_NAME="default"

$TMUX has-session -t $SESSION_NAME 2>/dev/null

if [ $? -eq 0 ]; then
  $TMUX attach-session -t $SESSION_NAME
else
  $TMUX new-session -s $SESSION_NAME -d -c ~/Developer/toolbox
  $TMUX attach-session -t $SESSION_NAME
fi