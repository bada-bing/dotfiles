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

  # TODO seems unnecessary, it is already in zprofile - Configure .zprofile for Homebrew
  # ZPROFILE_PATH="$HOME/.zprofile"
  # BREW_SHELLENV_LINE='eval "$(/opt/homebrew/bin/brew shellenv)"'

  # if ! grep -q "$BREW_SHELLENV_LINE" "$ZPROFILE_PATH" 2>/dev/null; then
  #   log "Adding Homebrew shellenv to $ZPROFILE_PATH"
  #   echo "$BREW_SHELLENV_LINE" >> "$ZPROFILE_PATH"
  # else
  #   log "Homebrew shellenv already configured in $ZPROFILE_PATH"
  # fi

  log "✅ Homebrew setup complete"
}

install_brew_packages() {
  log "Installing Homebrew packages from Brewfile"
  if [ -f "./Brewfile" ]; then
    brew bundle --file="./Brewfile"
  else
    log "Brewfile not found in the current directory. Skipping brew bundle."
  fi
  log "Homebrew package installation complete"
}

create_xdg_directories() {
  log "Creating XDG (Cross-Desktop Group) directories"
  
  # TODO seems that for macOS the `~/Library`` is better choice
  # https://stackoverflow.com/questions/3373948/equivalents-of-xdg-config-home-and-xdg-data-home-on-mac-os-x

  mkdir -p "$HOME/.config"
  mkdir -p "$HOME/.config/local/share"
  mkdir -p "$HOME/.config/cache"
}

# Function to set up dotfiles
# Clone dotfiles and run stow
setup_dotfiles() {
  log "Setting up dotfiles"

  clone_or_update_dotfiles() {
    local DOTFILES_DIR=~/dotfiles
    local repo_url=$1 # It will receive the final URL

    if ! command -v git &> /dev/null; then
      log "Git not found. Please ensure git is in your Brewfile."
      exit 1
    fi

    if [ -d "$DOTFILES_DIR" ]; then
      log "Dotfiles directory already exists. Pulling latest changes."
      (cd "$DOTFILES_DIR" && git pull) || { log "Failed to pull dotfiles updates."; exit 1; }
    else
      log "Cloning dotfiles repository from $repo_url."
      git clone "$repo_url" "$DOTFILES_DIR" || { log "Failed to clone dotfiles repository."; exit 1; }
    fi
  }

  symlink_dotfiles() {
    local DOTFILES_DIR=~/dotfiles

    if ! command -v stow &> /dev/null; then
      log "Stow not found. Please ensure stow is in your Brewfile."
      exit 1
    fi

    # An array to easily manage which directories to symlink from .config
    local config_packages_to_stow=(
      ghostty
      git
    )

    if [ ${#config_packages_to_stow[@]} -gt 0 ]; then
        log "Stowing specified .config directories: ${config_packages_to_stow[*]}"

        for pkg in "${config_packages_to_stow[@]}"; do
            # Use -R to restow, which is idempotent and safe.
            # -d specifies the stow directory containing the packages.
            # -t specifies the target directory for the symlinks.
            stow -R -d "$DOTFILES_DIR/.config" -t "$HOME/.config" "$pkg"
        done
    else
        log "No .config packages to stow."
    fi

    log "Selective dotfiles stowing complete."
  }
  read -p "Enter your dotfiles repository (e.g., 'user/repo' for GitHub, or a full URL): " DOTFILES_INPUT

  if [ -n "$DOTFILES_INPUT" ]; then
    local DOTFILES_URL
    # If the input doesn't contain '://' or '@', assume it's a GitHub user/repo.
    if [[ "$DOTFILES_INPUT" != *"://"* && "$DOTFILES_INPUT" != *"@"* ]]; then
      DOTFILES_URL="https://github.com/$DOTFILES_INPUT.git"
      log "Assuming GitHub repository: $DOTFILES_URL"
    else
      DOTFILES_URL="$DOTFILES_INPUT"
    fi

    clone_or_update_dotfiles "$DOTFILES_URL"
    symlink_dotfiles
    log "✅ finished dotfiles"
  else
    log "No dotfiles repository provided. Skipping dotfiles setup."
  fi
}

check_documents_setup() {
  log "Checking Documents folder setup"

  local DOCS_DIR="$HOME/Documents"
  local TOOLBOX_ENV_DIR="$DOCS_DIR/toolbox/env"
  local ICLOUD_BAK_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/BAK"

  # Check if documents folder is NOT empty AND it contains the specific folder.
  if [ -d "$DOCS_DIR" ] && [ "$(ls -A "$DOCS_DIR" 2>/dev/null)" ] && [ -d "$TOOLBOX_ENV_DIR" ]; then
    log "✅ Documents folder appears to be set up."
  else
    if [ ! -d "$ICLOUD_BAK_DIR" ]; then
        log "iCloud BAK folder not found at '$ICLOUD_BAK_DIR', cannot provide copy command."
        read -p "Press Enter to continue the setup script..."
        return
    fi
    
    log "Your Documents folder may need to be restored from your iCloud backup."
    echo "If it is empty or incomplete, you can run the following command in another terminal to restore it:"
    echo
    echo "mkdir -p \"$DOCS_DIR\""
    echo "cp -a \"$ICLOUD_BAK_DIR/.\" \"$DOCS_DIR/\""
    echo
    read -p "After running the command (or if you want to skip), press Enter to continue the setup script..."
  fi
}

# --- Main Execution ---

# Ensure the OS is a macOS
if [ "$(uname -s)" != "Darwin" ]; then
	log "This script is only for macOS"
	exit 1
fi

check_documents_setup 
# to pull private files from icloud (e.g., to ensure that git is configured)
set_hostname
set_macos_defaults
setup_homebrew
install_brew_packages
create_xdg_directories
setup_dotfiles

log "✅ Bootstrap script completed successfully!"