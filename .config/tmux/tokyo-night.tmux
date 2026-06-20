#!/usr/bin/env bash
# Tokyo Night Theme for tmux

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the color palette
source "$CURRENT_DIR/tokyo-night-palette.sh"

# Helper function to set tmux option
tmux_set() {
  local option="$1"
  local value="$2"
  tmux set-option -gq "$option" "$value"
}

# ===== STATUS BAR =====
tmux_set status-style "bg=${TN_BG},fg=${TN_FG}"

# ===== WINDOW STATUS =====
# Default window status (inactive)
tmux_set window-status-style "fg=${TN_DARK5}"
tmux_set window-status-format " #{?window_last_flag,◉ ,}#I:#W "

# Current/active window
tmux_set window-status-current-style "fg=${TN_BLUE},bold"
tmux_set window-status-current-format " ● #I:#W "

# Last window (use style only, format is same as default)
tmux_set window-status-last-style "fg=${TN_DARK5}"

# Window with activity
# tmux_set window-status-activity-style "fg=${TN_YELLOW},bold"

# Window with bell
# tmux_set window-status-bell-style "fg=${TN_RED},bold"

# Window separator
tmux_set window-status-separator ""

# ===== PANE BORDERS =====
# Inactive pane border
tmux_set pane-border-style "fg=${TN_BG_HIGHLIGHT}"

# Active pane border
tmux_set pane-active-border-style "fg=${TN_BLUE}"

# Pane number display (prefix + q)
tmux_set display-panes-active-colour "${TN_BLUE}"
tmux_set display-panes-colour "${TN_DARK5}"

# ===== MESSAGE & COMMAND LINE =====
tmux_set message-style "bg=${TN_BG_HIGHLIGHT},fg=${TN_FG}"
tmux_set message-command-style "bg=${TN_BG_HIGHLIGHT},fg=${TN_FG}"

# ===== COPY MODE =====
tmux_set mode-style "bg=${TN_BLUE0},fg=${TN_FG}"
