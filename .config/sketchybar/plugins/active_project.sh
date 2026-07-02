#!/bin/sh

ACTIVE_PROJECT=$(sh $HOME/Developer/toolbox/scripts/local_development/get_active_project.sh)

sketchybar --set "$NAME" label="$ACTIVE_PROJECT"
