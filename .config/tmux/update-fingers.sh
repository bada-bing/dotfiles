#!/usr/bin/env bash
# Sync tmux-fingers plugin source to match the brew-installed binary.
# Usage: after `brew upgrade tmux-fingers`, run this script.

set -e

version=$(tmux-fingers version 2>/dev/null)

if [[ -z "$version" ]]; then
  echo "Error: tmux-fingers binary not found. Run: brew install tmux-fingers"
  exit 1
fi

plugin_dir="$HOME/.config/tmux/plugins/tmux-fingers"
current=$(grep "^version" "$plugin_dir/shard.yml" | awk '{print $2}')

if [[ "$current" == "$version" ]]; then
  echo "Already at $version, nothing to do."
  exit 0
fi

echo "Updating plugin source: $current → $version"
git -C "$plugin_dir" fetch --tags
git -C "$plugin_dir" checkout "$version"
echo "Done. Reload tmux config with: prefix + r"
