#!/bin/sh

ACTIVE_TASK=$(sh ~/src/scripts/local_development/get_active_task.sh)

sketchybar --set "$NAME" label="$ACTIVE_TASK"
