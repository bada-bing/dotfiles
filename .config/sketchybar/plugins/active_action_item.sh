#!/bin/sh

ACTIVE_ACTION_ITEM=$(sh ~/src/scripts/local_development/get_active_action_item.sh)

sketchybar --set "$NAME" label="$ACTIVE_ACTION_ITEM"