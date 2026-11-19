#!/bin/bash

# --- macOS Defaults ---

# Finder: Show hidden files, show all extensions, use column view, show path bar, and sort folders first.
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.Finder FXPreferredViewStyle clmv
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Dock: Enable autohide, remove recent apps, and disable MRU spaces.
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock "mru-spaces" -bool false

# Mouse & Trackpad: Set scaling.
defaults write com.apple.mouse.scaling -float 3.0
defaults write com.apple.trackpad.scaling -float 3.0

# Kill affected applications to apply changes
for app in "Finder" "Dock"; do
  killall "$app" &> /dev/null
done
