#!/bin/sh

ACTIVE_ACTION_ITEM=$(sh $HOME/Developer/toolbox/scripts/local_development/get_active_action_item.sh)

sketchybar --set "$NAME" label="$ACTIVE_ACTION_ITEM"