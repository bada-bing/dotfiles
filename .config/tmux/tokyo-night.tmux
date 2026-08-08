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
# Every window renders as:  <lead> #I: #W <trail>
#
# Two marker slots, each owning one kind of fact, so they never collide:
#
#   lead   which window tmux is pointing at - ● current, ◉ last, blank
#          otherwise. Both sit *before* the index so the indices line up
#          down the whole bar; previously ● led and ◉ followed the index,
#          which is what made the row look crooked.
#   trail  whether the window needs Miki - ● red waiting, a spinning amber
#          braille glyph busy. @window_state is set per-window by
#          set_window_state.sh, driven from agent hooks or any wrapper
#          around slow work.
#
# The trail slot is reserved even when empty. A state appearing must not
# change the window's width, or every window to its right shifts. Braille
# glyphs are single-width, so the spinner keeps that promise.
#
# Waiting stays still on purpose: motion means work is happening, and a
# window that wants a decision is precisely one where nothing is. @spin is
# driven by spin_window_state.sh and falls back to a static dot whenever no
# animator is running - a frozen marker then reads as a stale one.
TN_TRAIL_WAITING="#[fg=${TN_RED}]#[bold] ●#[default]"
TN_TRAIL_BUSY="#[fg=${TN_YELLOW}]#[bold] #{?#{@spin},#{@spin},●}#[default]"
TN_TRAIL_NONE="  "

TN_TRAIL="#{?#{==:#{@window_state},waiting},${TN_TRAIL_WAITING},#{?#{==:#{@window_state},busy},${TN_TRAIL_BUSY},${TN_TRAIL_NONE}}}"

# Default window status (inactive)
tmux_set window-status-style "fg=${TN_DARK5}"
tmux_set window-status-format " #{?window_last_flag,◉, } #I: #W${TN_TRAIL} "

# Current/active window
tmux_set window-status-current-style "fg=${TN_BLUE},bold"
tmux_set window-status-current-format " ● #I: #W${TN_TRAIL} "

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
