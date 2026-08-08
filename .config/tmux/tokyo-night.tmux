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
# Window state marker. @window_state is set per-window by set_window_state.sh,
# driven from agent hooks or any wrapper script around slow work. Unset means
# nothing is running, so nothing is drawn.
# Style: dot-fg (glyph and coloured name) | fg (coloured name only) |
#        dot (glyph only) | bg (highlight the name).
#
# fg is the default: the status bar already draws ● for the current window
# and ◉ for the last one, so an extra glyph reads as a doubled bullet. The
# window name simply takes the state colour instead. choose-tree has no
# bullets of its own and keeps a circle (see TN_TREE_WIN below).
TN_STATE_STYLE="fg"

case "$TN_STATE_STYLE" in
  dot)
    TN_STATE_ON_WAITING="#[fg=${TN_RED}]●#[default] "
    TN_STATE_ON_BUSY="#[fg=${TN_YELLOW}]●#[default] "
    TN_STATE_OFF=""
    ;;
  fg)
    TN_STATE_ON_WAITING="#[fg=${TN_RED}]#[bold]"
    TN_STATE_ON_BUSY="#[fg=${TN_YELLOW}]#[bold]"
    TN_STATE_OFF="#[default]"
    ;;
  bg)
    # Styles are split into separate #[...] groups on purpose: a comma inside
    # a #[...] would be read as a branch separator by the #{?...} conditional.
    TN_STATE_ON_WAITING="#[bg=${TN_RED}]#[fg=${TN_BG}]"
    TN_STATE_ON_BUSY="#[bg=${TN_YELLOW}]#[fg=${TN_BG}]"
    TN_STATE_OFF="#[default]"
    ;;
  *)
    # dot-fg: the bullet keeps its colour through the window name, so no
    # reset between them.
    TN_STATE_ON_WAITING="#[fg=${TN_RED}]#[bold]● "
    TN_STATE_ON_BUSY="#[fg=${TN_YELLOW}]#[bold]● "
    TN_STATE_OFF="#[default]"
    ;;
esac

TN_STATE="#{?#{==:#{@window_state},waiting},${TN_STATE_ON_WAITING},#{?#{==:#{@window_state},busy},${TN_STATE_ON_BUSY},}}"

# Default window status (inactive)
tmux_set window-status-style "fg=${TN_DARK5}"
tmux_set window-status-format " ${TN_STATE}#I: #{?window_last_flag,◉ ,}#W${TN_STATE_OFF} "

# Current/active window
tmux_set window-status-current-style "fg=${TN_BLUE},bold"
tmux_set window-status-current-format " ${TN_STATE}● #I: #W${TN_STATE_OFF} "

# ===== CHOOSE-TREE (prefix + s) =====
# tmux's own default tree format, with a window state marker added. Rows are told
# apart by pane_format / window_format, which are only true on pane and window
# rows; a session row has neither. Bound here rather than in tmux.conf because
# the marker needs the palette.

# choose-tree keeps plain circles - it draws no bullets of its own, so a
# filled dot is the clearest marker there.
# A window row shows its own state.
TN_TREE_WIN="#{?#{==:#{@window_state},waiting},#[fg=${TN_RED}]●#[default] ,#{?#{==:#{@window_state},busy},#[fg=${TN_YELLOW}]●#[default] ,}}"

# A session row shows the state rolled up from its windows. #{W:...} expands
# once per window, so a non-empty match means at least one window is in it.
TN_TREE_SES="#{?#{m:*W*,#{W:#{?#{==:#{@window_state},waiting},W,}}},#[fg=${TN_RED}]●#[default] ,#{?#{m:*B*,#{W:#{?#{==:#{@window_state},busy},B,}}},#[fg=${TN_YELLOW}]●#[default] ,}}"

TN_TREE_FORMAT="#{?pane_format,#{?pane_marked,#[reverse],}#{pane_current_command}#{pane_flags},#{?window_format,${TN_TREE_WIN}#{?window_marked_flag,#[reverse],}#{window_name}#{window_flags},${TN_TREE_SES}#{session_windows} windows#{?session_grouped, (group #{session_group}),}#{?session_attached, (attached),}}}"

tmux bind-key s choose-tree -Zs -F "$TN_TREE_FORMAT"

# The preview label. tmux's default shows pane_index:pane_title on a pane row
# but only window_index:window_name on a window row, so the agent's own
# description disappears depending on which row is selected. Show the pane
# title in both cases - that is the useful half.
tmux set-option -gwq tree-mode-preview-format "#{?pane_format,#{pane_index}: #{pane_title},#{window_index}:#{window_name} · #{pane_title}}"

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
