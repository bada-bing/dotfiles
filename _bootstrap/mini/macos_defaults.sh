#!/bin/bash

# The Mac mini changes as little as possible: it never goes to sleep,
# and it starts again by itself after a power failure.
# sudo runs only for a value that differs, so a second run asks for no password.

# Prints the current value of a power setting.
get_power_setting() {
  pmset -g | awk -v key="$1" '$1 == key { print $2 }'
}

# Sets a power setting on every power source. A value already in place is left alone, without sudo.
set_power_setting() {
  local key="$1" value="$2"
  if [ "$(get_power_setting "$key")" = "$value" ]; then
    echo "  • $key is already $value"
  else
    echo "  • Setting $key to $value"
    sudo pmset -a "$key" "$value"
  fi
}

set_power_setting sleep 0
set_power_setting autorestart 1
