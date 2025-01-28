#!/bin/sh

ACTIVE_PROJECT=$(sh ~/src/scripts/local_development/get_active_project.sh)

sketchybar --set "$NAME" label="$ACTIVE_PROJECT"
