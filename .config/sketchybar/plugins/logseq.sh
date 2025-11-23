#!/bin/sh

# The $NAME variable is passed from sketchybar and holds the name of
# the item invoking this script:
# https://felixkratz.github.io/SketchyBar/config/events#events-and-scripting


# To make the logseq page dynamic, check how it is done in wa-2/logseq-sessionizer 

TASK=$(sh ~/src/scripts/local_development/get_logseq_today_active_task.sh | tr -d '"')

sketchybar --set "$NAME" label="$TASK" icon="$($CONFIG_DIR/plugins/icon_map_fn.sh "Logseq")"