#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

log() {
  echo "--- $1 ---"
}

set_hostname() {
  log "Setting hostname"
  CURRENT_HOSTNAME=$(scutil --get LocalHostName)
  log "Current hostname is $CURRENT_HOSTNAME"
  read -p "Enter new hostname (leave blank to keep current): " NEW_HOSTNAME

  if [ -n "$NEW_HOSTNAME" ] && [ "$NEW_HOSTNAME" != "$CURRENT_HOSTNAME" ]; then
    log "Setting hostname to $NEW_HOSTNAME"
    sudo scutil --set LocalHostName "$NEW_HOSTNAME"
    sudo scutil --set ComputerName "$NEW_HOSTNAME"
    sudo scutil --set HostName "$NEW_HOSTNAME"
    log "✅ Hostname set to $CURRENT_HOSTNAME"
  else
    log "✅ Hostname remains $CURRENT_HOSTNAME"
  fi
}

set_macos_defaults() {
  log "Setting macOS defaults"

  DEFAULTS_FILE="./macos_defaults.list" # Assuming script is run from _bootstrap

  if [ -f "$DEFAULTS_FILE" ]; then
    while IFS= read -r line; do
      # Ignore comments and empty lines
      if [[ -n "$line" && ! "$line" =~ ^\s*# ]]; then
        eval "$line"
      fi
    done < "$DEFAULTS_FILE"
  else
    log "❓ Defaults file not found: $DEFAULTS_FILE"
  fi

  # Kill affected applications to apply changes
  for app in "Finder" "Dock"; do
    killall "$app" &> /dev/null
  done

  log "✅ finished macOS defaults"
}

setup_homebrew() {
  log "Setting up Homebrew"

  # Check for Homebrew and install if we don't have it
  if ! command -v brew &> /dev/null; then
    log "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
    # Ensure Homebrew is in the PATH for the current script execution
    eval "$(/opt/homebrew/bin/brew shellenv)"

  else
    log "Homebrew is already installed. Updating"
    # TODO do I need to update? should I also upgrade?
    brew update
  fi

  log "✅ Homebrew setup complete"
}

install_brew_packages() {
  log "Installing Homebrew packages from Brewfile"
  if [ -f "./Brewfile" ]; then
    brew bundle --file="./Brewfile"
    brew bundle --file="./Brewfile.utils"
    brew bundle --file="./Brewfile.dev"
    brew bundle --file="./Brewfile.workstation"
  else
    log "Brewfile not found in the current directory. Skipping brew bundle."
  fi
  log "Homebrew package installation complete"
}

create_xdg_directories() {
  log "Creating XDG (Cross-Desktop Group) directories"

  # related: https://stackoverflow.com/questions/3373948/equivalents-of-xdg-config-home-and-xdg-data-home-on-mac-os-x
  for dir in "$HOME/.config" "$HOME/.local/share" "$HOME/.cache"; do
    if [ -d "$dir" ]; then
      log "Directory $dir already exists."
    else
      mkdir -p "$dir"
      log "Created directory $dir."
    fi
  done

  log "✅ XDG directories check complete."
}

# Function to set up dotfiles
# Clone dotfiles and run stow
setup_dotfiles() {
  log "Setting up dotfiles"

  # TODO symlink zprofile and zsh
  symlink_dotfiles() {
    local DOTFILES_DIR=~/dotfiles

    if ! command -v stow &> /dev/null; then
      log "Stow not found. Ensure stow is in your Brewfile."
      exit 1
    fi

    # An array to easily manage which directories to symlink from .config
    local config_packages_to_stow=(
      lazygit
      gh
      ghostty
      git
    )

    if [ ${#config_packages_to_stow[@]} -gt 0 ]; then
        log "Stowing specified .config directories: ${config_packages_to_stow[*]}"

        for pkg in "${config_packages_to_stow[@]}"; do
            local source_path="$DOTFILES_DIR/.config/$pkg"
            local target_path="$HOME/.config/$pkg"
            
            if [ -L "$target_path" ]; then
                # It is a symlink. Check if it's the correct one.
                local link_content
                link_content=$(readlink "$target_path")

                # The expected relative path from ~/.config/ to ~/dotfiles/.config/pkg
                local expected_relative_path="../dotfiles/.config/$pkg"

                if [ "$link_content" = "$source_path" ] || [ "$link_content" = "$expected_relative_path" ]; then
                    log "✅ Symlink for '$pkg' already exists and is correct."
                else
                    log "⚠️  Conflict: '$target_path' is a symlink. It points to '$link_content', but should point to '$source_path' (absolute) or '$expected_relative_path' (relative). Exiting."
                    exit 1
                fi
            elif [ -e "$target_path" ]; then
                # It is a file or directory.
                log "⚠️  Conflict: '$target_path' already exists and is not a symlink. Exiting."
                exit 1
            else
                # It does not exist. Create it.
                ln -s "$source_path" "$target_path"
                log "✅ Symlink for '$pkg' created."
            fi
        done
    else
        log "No .config packages to stow."
    fi

    log "Selective dotfiles stowing complete."
  }

  local DOTFILES_DIR=~/dotfiles

  if ! command -v git &> /dev/null; then
    log "Git not found. Ensure git is in your Brewfile."
    exit 1
  fi

  if [ -d "$DOTFILES_DIR" ]; then
    log "Dotfiles directory '$DOTFILES_DIR' already exists. Pulling latest changes."
    (cd "$DOTFILES_DIR" && git pull) || { log "Failed to pull dotfiles updates."; exit 1; }
  else
    log "Dotfiles directory not found. Cloning repository."
    
    local suggested_repo=""
    # This suggestion logic is based on the script's location.
    # It assumes the script is inside a checkout of the dotfiles repo, even if it's not at ~/dotfiles.
    if git -C .. rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        local remote_url=$(git -C .. remote get-url origin 2>/dev/null)
        if [ -n "$remote_url" ]; then
            local suggested_user=$(echo "$remote_url" | awk -F'[:/]' '{print $(NF-1)}')
            if [ -n "$suggested_user" ]; then
                suggested_repo="$suggested_user/dotfiles"
            fi
        fi
    fi

    local DOTFILES_INPUT=""
    if [ -n "$suggested_repo" ]; then
        read -p "Use '$suggested_repo' as your dotfiles repository? [Y/n] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            read -p "Enter your dotfiles repository: " DOTFILES_INPUT
        else
            DOTFILES_INPUT="$suggested_repo"
        fi
    else
        read -p "Enter your dotfiles repository: " DOTFILES_INPUT
    fi

    if [ -n "$DOTFILES_INPUT" ]; then
        local DOTFILES_URL
        if [[ "$DOTFILES_INPUT" != *"://"* && "$DOTFILES_INPUT" != *"@"* ]]; then
            DOTFILES_URL="https://github.com/$DOTFILES_INPUT.git"
            log "Assuming GitHub repository: $DOTFILES_URL"
        else
            DOTFILES_URL="$DOTFILES_INPUT"
        fi
        log "Cloning dotfiles repository from $DOTFILES_URL."
        git clone "$DOTFILES_URL" "$DOTFILES_DIR" || { log "Failed to clone dotfiles repository."; exit 1; }
    else
        log "No dotfiles repository provided. Skipping dotfiles setup."
        return
    fi
  fi
  
  symlink_dotfiles
  log "✅ finished dotfiles"
}

bootstrap_documents_folder() {
  log "Checking Documents folder setup"

  local DOCS_DIR="$HOME/Documents"
  local TOOLBOX_ENV_DIR="$DOCS_DIR/toolbox/env"
  local ICLOUD_BAK_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/BAK"

  # Check if documents folder is NOT empty AND it contains the specific folder.
  if [ -d "$DOCS_DIR" ] && [ "$(ls -A "$DOCS_DIR" 2>/dev/null)" ] && [ -d "$TOOLBOX_ENV_DIR" ]; then
    # It is an explict decision to manually reconcile the difference between iCloud and Documents
    local ICLOUD_TOOLBOX_ENV_DIR="$ICLOUD_BAK_DIR/toolbox/env"

    if [ -d "$ICLOUD_TOOLBOX_ENV_DIR" ]; then
      DOCS_TOOLBOX_SIZE=$(du -sh "$TOOLBOX_ENV_DIR" | awk '{print $1}')
      ICLOUD_TOOLBOX_SIZE=$(du -sh "$ICLOUD_TOOLBOX_ENV_DIR" | awk '{print $1}')

      if [ "$DOCS_TOOLBOX_SIZE" != "$ICLOUD_TOOLBOX_SIZE" ]; then
        log "⚠️  Mismatch in toolbox/env directory size:"
        log "   Documents/toolbox/env size: $DOCS_TOOLBOX_SIZE"
        log "   iCloud BAK/toolbox/env size: $ICLOUD_TOOLBOX_SIZE"
        log "Reconcile the differences manually. Exiting."
        exit 1
      else
        log "✅ Documents/toolbox/env size matches iCloud BAK/toolbox/env size ($DOCS_TOOLBOX_SIZE)."
      fi
    else
      log "⚠️  iCloud BAK/toolbox/env directory not found at '$ICLOUD_TOOLBOX_ENV_DIR'. Cannot compare sizes."
    fi
    log "✅ Documents folder appears to be set up."
  else
    if [ ! -d "$ICLOUD_BAK_DIR" ]; then
        log "ERROR: iCloud BAK folder not found at '$ICLOUD_BAK_DIR'. Exiting."
        exit 1
    fi
    
    log "The 'toolbox/env' directory is missing from your Documents folder. It should be restored from the iCloud backup."
    echo "Run the following command to restore it:"
    echo
    echo "mkdir -p \"$DOCS_DIR\""
    echo "cp -a \"$ICLOUD_BAK_DIR/.\" \"$DOCS_DIR/\""
    echo
    read -p "After running the command (or if you want to skip), press Enter to continue the setup script..."
  fi
}

configure_application_settings() {
  log "Reminder: Import Raycast settings. The settings file is in your ~/Documents/toolbox/env/ folder."
}

# --- Main Execution ---

# Ensure the OS is a macOS
if [ "$(uname -s)" != "Darwin" ]; then
	log "This script is only for macOS"
	exit 1
fi

bootstrap_documents_folder # pull private files from icloud (e.g., to ensure that git is configured)
set_hostname
set_macos_defaults
setup_homebrew
install_brew_packages
create_xdg_directories
setup_dotfiles
configure_application_settings

log "✅ Bootstrap script completed successfully!"