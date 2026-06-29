#!/bin/bash

eval "$(/opt/homebrew/bin/brew shellenv)"

export TOOLBOX_DIR=~/Developer/toolbox
export PATH="/opt/homebrew/bin:$PATH"

bash "$TOOLBOX_DIR/scripts/dev-env/default_session.sh"