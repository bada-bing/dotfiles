#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Logging functions ---
C_BLUE="\033[1;34m"
C_GREEN="\033[0;32m"
C_YELLOW="\033[1;33m"
C_RESET="\033[0m"

header() {
  echo -e "
${C_BLUE}--- ${1} ---${C_RESET}"
}

info() {
  echo -e "  • ${1}"
}

success() {
  echo -e "  ${C_GREEN}✓${C_RESET} ${1}"
}

warn() {
    echo -e "  ${C_YELLOW}✗${C_RESET} ${1}"
}

prompt() {
  # The space after the prompt is intentional for better readability
  read -p "  _ ${1} " "${@:2}"
}

prompt_secret() {
  read -s -p "  _ ${1} " "${@:2}"
}

print_ssh_key_instructions() {
  info "1. Open your browser and go to https://github.com/settings/keys"
  info "2. Click on 'New SSH key'."
  info "3. Set a title (e.g., '$(scutil --get LocalHostName)')."
  info "4. Paste the key from your clipboard into the 'Key' field."
  info "5. Click 'Add SSH key'."
}

ensure_github_ssh_access() {
  header "Checking for GitHub SSH access"

  local key_path="$HOME/.ssh/id_ed25519"
  local new_key_generated=false

  # Ensure .ssh directory exists
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  if [ ! -f "$key_path" ]; then
    info "No SSH key found. Generating a new one."
    prompt "Enter your GitHub email address:" user_email
    
    if [ -z "$user_email" ]; then
      warn "Email address cannot be empty. Exiting."
      exit 1
    fi

    local passphrase=""
    while true; do
      prompt_secret "Enter a passphrase for your new SSH key (leave empty for no passphrase):" passphrase
      echo
      if [ -z "$passphrase" ]; then
        info "Creating key without a passphrase."
        break
      fi
      prompt_secret "Confirm passphrase:" passphrase_confirm
      echo
      if [ "$passphrase" = "$passphrase_confirm" ]; then
        info "Passphrase confirmed."
        break
      else
        warn "Passphrases do not match. Please try again."
      fi
    done

    ssh-keygen -t ed25519 -C "$user_email" -f "$key_path" -N "$passphrase"
    new_key_generated=true
    
    success "New SSH key generated."
  else
    info "Existing SSH key found at $key_path."
  fi

  info "Ensuring ssh-agent is running and key is added to keychain..."
  # The `ssh-add -l` command will return a non-zero exit code if the agent is not running.
  if ! ssh-add -l &> /dev/null; then
    info "ssh-agent not running. Starting a new one for this script session..."
    eval "$(ssh-agent -s)"
  fi

  # Add the key to the agent if it's not already loaded.
  # We check for the key's filename in the output of ssh-add -l.
  if ! ssh-add -l | grep -q "id_ed25519"; then
    info "Adding SSH identity to the agent..."
    ssh-add --apple-use-keychain "$key_path"
  else
    info "SSH identity is already loaded in the agent."
  fi

  if [ "$new_key_generated" = true ]; then
    pbcopy < "${key_path}.pub"
    success "Your new public SSH key has been copied to the clipboard."
    info "Add key to your GitHub account."
    echo
    print_ssh_key_instructions
  else
    info "Script assumes existing SSH key is already on GitHub account. If not, add it to your GitHub account."
    prompt "Need a reminder on how to add it? [y/N] " -n 1 -r REPLY
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      info "You can copy your public key to the clipboard by running:"
      info "cat ~/.ssh/id_ed25519.pub | pbcopy"
      echo
      print_ssh_key_instructions
    fi
  fi
  
  echo
  prompt "Press Enter to continue once your SSH key is configured on GitHub."

  info "Verifying SSH connection to GitHub..."
  # Use -o StrictHostKeyChecking=accept-new to automatically add GitHub's host key
  # The 2>&1 redirects stderr to stdout to grep the success message
  if ssh -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    success "GitHub SSH connection successful."
  else
    warn "Could not verify GitHub SSH connection. The script will continue, but you may face issues with private repositories."
  fi
}

set_hostname() {
  header "Setting hostname"
  CURRENT_HOSTNAME=$(scutil --get LocalHostName)
  info "Current hostname is $CURRENT_HOSTNAME"
  prompt "Enter new hostname (leave blank to keep current):" NEW_HOSTNAME

  if [ -n "$NEW_HOSTNAME" ] && [ "$NEW_HOSTNAME" != "$CURRENT_HOSTNAME" ]; then
    info "Setting hostname to $NEW_HOSTNAME"
    sudo scutil --set LocalHostName "$NEW_HOSTNAME"
    sudo scutil --set ComputerName "$NEW_HOSTNAME"
    sudo scutil --set HostName "$NEW_HOSTNAME"
    success "Hostname set to $NEW_HOSTNAME"
  else
    success "Hostname remains $CURRENT_HOSTNAME"
  fi
}

set_macos_defaults() {
  header "Setting macOS defaults"

  DEFAULTS_FILE="./macos_defaults.list" # Assuming script is run from _bootstrap

  if [ -f "$DEFAULTS_FILE" ]; then
    while IFS= read -r line; do
      # Ignore comments and empty lines
      if [[ -n "$line" && ! "$line" =~ ^\s*# ]]; then
        eval "$line"
      fi
    done < "$DEFAULTS_FILE"
  else
    warn "Defaults file not found: $DEFAULTS_FILE"
  fi

  # Kill affected applications to apply changes
  for app in "Finder" "Dock"; do
    killall "$app" &> /dev/null
  done

  success "Finished macOS defaults"
}

setup_homebrew() {
  header "Setting up Homebrew"

  # Check for Homebrew and install it if necessary
  if ! command -v brew &> /dev/null; then
    info "Installing Homebrew"
    # The brew installation script takes care of Xcode Command Line Tools (CLT)
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
    # Ensure Homebrew is in the PATH for the current script execution
    eval "$(/opt/homebrew/bin/brew shellenv)"

  else
    info "Homebrew is already installed. Updating"
    # TODO do I need to update? should I also upgrade?
    brew update
  fi

  success "Homebrew setup complete"
}

install_homebrew_packages() {
  header "Installing Homebrew packages from Brewfile"
  if [ -f "./Brewfile" ]; then
    brew bundle --file="./Brewfile"
    brew bundle --file="./Brewfile.utils"
    brew bundle --file="./Brewfile.dev"
    brew bundle --file="./Brewfile.workstation"
  else
    info "Brewfile not found in the current directory. Skipping brew bundle."
  fi
  success "Homebrew package installation complete"
}

create_xdg_directories() {
  header "Creating XDG (Cross-Desktop Group) directories"

  # related: https://stackoverflow.com/questions/3373948/equivalents-of-xdg-config-home-and-xdg-data-home-on-mac-os-x
  for dir in "$HOME/.config" "$HOME/.local/share" "$HOME/.cache"; do
    if [ -d "$dir" ]; then
      info "Directory $dir already exists."
    else
      mkdir -p "$dir"
      info "Created directory $dir."
    fi
  done

  success "XDG directories check complete."
}

# Function to set up dotfiles
# Clone dotfiles and run stow
setup_dotfiles() {
  header "Setting up dotfiles"

  # TODO symlink zprofile and zsh
  symlink_dotfiles() {
    local DOTFILES_DIR=~/dotfiles

    if ! command -v stow &> /dev/null; then
      warn "Stow not found. Ensure stow is in your Brewfile."
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
        info "Stowing specified .config directories: ${config_packages_to_stow[*]}"

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
                    success "Symlink for '$pkg' already exists and is correct."
                else
                    warn "Conflict: '$target_path' is a symlink. It points to '$link_content', but should point to '$source_path' (absolute) or '$expected_relative_path' (relative). Exiting."
                    exit 1
                fi
            elif [ -e "$target_path" ]; then
                # It is a file or directory.
                warn "Conflict: '$target_path' already exists and is not a symlink. Exiting."
                exit 1
            else
                # It does not exist. Create it.
                ln -s "$source_path" "$target_path"
                success "Symlink for '$pkg' created."
            fi
        done
    else
        info "No .config packages to stow."
    fi

    success "Selective dotfiles stowing complete."
  }

  local DOTFILES_DIR=~/dotfiles

  if ! command -v git &> /dev/null; then
    warn "Git not found. Ensure git is in your Brewfile."
    exit 1
  fi

  if [ -d "$DOTFILES_DIR" ]; then
    info "Dotfiles directory '$DOTFILES_DIR' already exists. Pulling latest changes."
    (cd "$DOTFILES_DIR" && git pull) || { warn "Failed to pull dotfiles updates."; exit 1; }
  else
    info "Dotfiles directory not found. Cloning repository."
    
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
        prompt "Use '$suggested_repo' as your dotfiles repository? [Y/n]" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            prompt "Enter your dotfiles repository:" DOTFILES_INPUT
        else
            DOTFILES_INPUT="$suggested_repo"
        fi
    else
        prompt "Enter your dotfiles repository:" DOTFILES_INPUT
    fi

    if [ -n "$DOTFILES_INPUT" ]; then
        local DOTFILES_URL
        if [[ "$DOTFILES_INPUT" != *"://"* && "$DOTFILES_INPUT" != *"@"* ]]; then
            DOTFILES_URL="https://github.com/$DOTFILES_INPUT.git"
            info "Assuming GitHub repository: $DOTFILES_URL"
        else
            DOTFILES_URL="$DOTFILES_INPUT"
        fi
        info "Cloning dotfiles repository from $DOTFILES_URL."
        git clone "$DOTFILES_URL" "$DOTFILES_DIR" || { warn "Failed to clone dotfiles repository."; exit 1; }
    else
        info "No dotfiles repository provided. Skipping dotfiles setup."
        return
    fi
  fi
  
  symlink_dotfiles
  success "Finished dotfiles setup"
}

bootstrap_env_folder() {
  header "Checking Documents folder setup"

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
        warn "Mismatch in toolbox/env directory size:"
        info "   Documents/toolbox/env size: $DOCS_TOOLBOX_SIZE"
        info "   iCloud BAK/toolbox/env size: $ICLOUD_TOOLBOX_SIZE"
        warn "Reconcile the differences manually. Exiting."
        exit 1
      else
        success "Documents/toolbox/env size matches iCloud BAK/toolbox/env size ($DOCS_TOOLBOX_SIZE)."
      fi
    else
      warn "iCloud BAK/toolbox/env directory not found at '$ICLOUD_TOOLBOX_ENV_DIR'. Cannot compare sizes."
    fi
    success "Documents folder appears to be set up."
  else
    if [ ! -d "$ICLOUD_BAK_DIR" ]; then
        warn "iCloud BAK folder not found at '$ICLOUD_BAK_DIR'. Exiting."
        exit 1
    fi
    
    info "The 'toolbox/env' directory is missing from your Documents folder. It should be restored from the iCloud backup."
    echo "Run the following command to restore it:"
    echo
    echo "mkdir -p "$DOCS_DIR""
    echo "cp -a "$ICLOUD_BAK_DIR/." "$DOCS_DIR/""
    echo
    prompt "After running the command (or if you want to skip), press Enter to continue the setup script..."
  fi
}

configure_application_settings() {
  header "Manual Action Required: Configure Application Settings"
  info "Search for 'Application Settings' in RemNote for the details."
  prompt "Once you are done, press Enter to continue..."
}

# --- Main Execution ---

# Ensure the OS is a macOS
if [ "$(uname -s)" != "Darwin" ]; then
	warn "This script is only for macOS"
	exit 1
fi

bootstrap_env_folder # pull private files from icloud (e.g., git configuration)
ensure_github_ssh_access
set_hostname
setup_homebrew
install_homebrew_packages
create_xdg_directories
setup_dotfiles
set_macos_defaults
configure_application_settings

success "Bootstrap script completed successfully!"