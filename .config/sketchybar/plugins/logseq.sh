#!/bin/sh

# The $NAME variable is passed from sketchybar and holds the name of
# the item invoking this script:
# https://felixkratz.github.io/SketchyBar/config/events#events-and-scripting


# To make the logseq page dynamic, check how it is done in wa-2/logseq-sessionizer 

RESULT=$(curl --request POST \
  --url http://127.0.0.1:12315/api \
  --header 'authorization: Bearer d3183aef-d30a-4936-a370-018ee1b425ed' \
  --header 'content-type: application/json' \
  --header 'user-agent: vscode-restclient' \
  --data '{"method": "logseq.db.q", "args": ["(and (task NOW) [[WPR-16235-introduce-scripting-integration-in-cart-ui-next]])"]}' | jq '.[0].content')

RESULT=$(echo "$RESULT" | tr -d '"')

sketchybar --set "$NAME" label="$RESULT" icon="$($CONFIG_DIR/plugins/icon_map_fn.sh "Logseq")"