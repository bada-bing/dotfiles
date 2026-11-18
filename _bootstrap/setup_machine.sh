#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Logging functions ---
C_BLUE="\033[1;34m"
C_GREEN="\033[0;32m"
C_YELLOW="\033[1;33m"
C_RESET="\033[0m"

# --- Path Constants ---
DOTFILES_DIR="$HOME/Developer/toolbox/dotfiles"
BOOTSTRAP_DIR="$DOTFILES_DIR/_bootstrap"

# --- State ---
MACHINE="" # the machine's folder in the dotfiles, set by set_hostname

header() {
  echo -e " ${C_BLUE}--- ${1} ---${C_RESET}"
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

# The machine whose folder is linked: the one chosen in set_hostname, or else this machine's LocalHostName.
machine_name() {
  echo "${MACHINE:-$(scutil --get LocalHostName)}"
}

# A machine's folder sits at the root of the dotfiles and is laid out as its home directory,
# so it holds a .config. A folder with a leading underscore is not a machine.
list_machine_folders() {
  local dir name
  for dir in "$DOTFILES_DIR"/*/; do
    name=$(basename "$dir")
    [[ "$name" == _* ]] && continue
    [ -d "$dir/.config" ] || continue
    echo "$name"
  done
}

print_ssh_key_instructions() {
  info "1. Open your browser and go to https://github.com/settings/keys"
  info "2. Click on 'New SSH key'."
  info "3. Set a title (e.g., '$(scutil --get LocalHostName)')."
  info "4. Paste the key from your clipboard into the 'Key' field."
  info "5. Click 'Add SSH key'."
}

# --- Steps ---

bootstrap_env_folder() {
  header "Checking toolbox/private folder setup"

  local TOOLBOX_PRIVATE_DIR="$HOME/Developer/toolbox/private"
  local TOOLBOX_ENV_DIR="$TOOLBOX_PRIVATE_DIR/env"
  local ICLOUD_BAK_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/BAK"

  # Check if the private toolbox folder is already present.
  if [ -d "$TOOLBOX_ENV_DIR" ]; then
    local ICLOUD_TOOLBOX_ENV_DIR="$ICLOUD_BAK_DIR/toolbox/env"

    if [ -d "$ICLOUD_TOOLBOX_ENV_DIR" ]; then
      TOOLBOX_SIZE=$(du -sh "$TOOLBOX_ENV_DIR" | awk '{print $1}')
      ICLOUD_TOOLBOX_SIZE=$(du -sh "$ICLOUD_TOOLBOX_ENV_DIR" | awk '{print $1}')

      if [ "$TOOLBOX_SIZE" != "$ICLOUD_TOOLBOX_SIZE" ]; then
        warn "Mismatch in toolbox/env directory size:"
        info "   Developer/toolbox/private/env size: $TOOLBOX_SIZE"
        info "   iCloud BAK/toolbox/env size: $ICLOUD_TOOLBOX_SIZE"
        warn "Reconcile the differences manually. Exiting."
        exit 1
      else
        success "toolbox/private/env size matches iCloud BAK/toolbox/env size ($TOOLBOX_SIZE)."
      fi
    else
      warn "iCloud BAK/toolbox/env directory not found at '$ICLOUD_TOOLBOX_ENV_DIR'. Cannot compare sizes."
    fi
    success "toolbox/private folder appears to be set up."
  else
    if [ ! -d "$ICLOUD_BAK_DIR" ]; then
        warn "iCloud BAK folder not found at '$ICLOUD_BAK_DIR'. Exiting."
        exit 1
    fi

    info "The toolbox/private folder is missing. It should be restored from the iCloud backup."
    echo "Run the following command to restore it:"
    echo
    echo "mkdir -p \"$TOOLBOX_PRIVATE_DIR\""
    echo "cp -a \"$ICLOUD_BAK_DIR/.\" \"$TOOLBOX_PRIVATE_DIR/\""
    echo
    prompt "After running the command (or if you want to skip), press Enter to continue the setup script..."
  fi
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
    brew update # ensure latest formula/cask metadata before `brew bundle`
  fi

  if ! command -v stow &> /dev/null; then
    info "Installing GNU Stow (required to symlink dotfiles)"
    brew install stow
  fi

  success "Homebrew setup complete"
}

clone_dotfiles() {
  header "Cloning dotfiles"

  if ! command -v git &> /dev/null; then
    warn "Git not found. It comes with the Xcode Command Line Tools, which the Homebrew installation installs."
    exit 1
  fi

  if [ -d "$DOTFILES_DIR" ]; then
    info "Dotfiles directory '$DOTFILES_DIR' already exists. Pulling latest changes."
    git -C "$DOTFILES_DIR" pull || { warn "Failed to pull dotfiles updates."; exit 1; }
  else
    info "Dotfiles directory not found. Cloning repository."

    local suggested_repo=""
    # This suggestion logic is based on the script's location.
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

    if [ -z "$DOTFILES_INPUT" ]; then
        warn "No dotfiles repository provided. Exiting."
        exit 1
    fi

    local DOTFILES_URL
    if [[ "$DOTFILES_INPUT" != *"://"* && "$DOTFILES_INPUT" != *"@"* ]]; then
        DOTFILES_URL="https://github.com/$DOTFILES_INPUT.git"
        info "Assuming GitHub repository: $DOTFILES_URL"
    else
        DOTFILES_URL="$DOTFILES_INPUT"
    fi
    info "Cloning dotfiles repository from $DOTFILES_URL."
    git clone "$DOTFILES_URL" "$DOTFILES_DIR" || { warn "Failed to clone dotfiles repository."; exit 1; }
  fi

  success "Dotfiles are in $DOTFILES_DIR"
}

set_hostname() {
  header "Setting hostname"

  local computer_name=$(scutil --get ComputerName)
  local local_host_name=$(scutil --get LocalHostName)
  local host_name=$(scutil --get HostName)

  if [ "$computer_name" != "$local_host_name" ] || [ "$local_host_name" != "$host_name" ]; then
    warn "Hostname inconsistency detected:"
    info "  ComputerName:  $computer_name"
    info "  LocalHostName: $local_host_name"
    info "  HostName:      $host_name"
    info "Enter a new name to ensure that they are consistent."
  else
    info "Current hostname is $local_host_name"
  fi

  # The hostname names the machine's folder in the dotfiles, which link_dotfiles links.
  local machines=()
  local name
  while IFS= read -r name; do
    machines+=("$name")
  done < <(list_machine_folders)

  local new_hostname=""
  if [ ${#machines[@]} -gt 0 ]; then
    info "Machines with a folder in the dotfiles:"
    for i in "${!machines[@]}"; do
      info "  $((i+1))) ${machines[$i]}"
    done
    prompt "Choose a number, type a new hostname, or leave blank to keep current:" new_hostname
  else
    prompt "Enter new hostname (leave blank to keep current):" new_hostname
  fi

  if [[ "$new_hostname" =~ ^[0-9]+$ ]] && [ "$new_hostname" -ge 1 ] && [ "$new_hostname" -le "${#machines[@]}" ]; then
    new_hostname="${machines[$((new_hostname - 1))]}"
  fi

  if [ -n "$new_hostname" ]; then
    info "Setting hostname to $new_hostname"
    sudo scutil --set LocalHostName "$new_hostname"
    sudo scutil --set ComputerName "$new_hostname"
    sudo scutil --set HostName "$new_hostname"
    MACHINE="$new_hostname"
    success "Hostname set to $new_hostname"
  else
    if [ "$computer_name" = "$local_host_name" ] && [ "$local_host_name" = "$host_name" ]; then
      success "Hostname remains $local_host_name"
    else
      warn "Hostname inconsistency not resolved."
    fi
  fi
}

create_xdg_directories() {
  header "Creating XDG (Cross-Desktop Group) directories"

  # related: https://stackoverflow.com/questions/3373948/equivalents-of-xdg-config-home-and-xdg-data-home-on-mac-os-x
  # Created before the dotfiles are linked: stow links a missing ~/.config as one symlink into the
  # repository, and every file a tool writes there would then land in the dotfiles.
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

link_dotfiles() {
  header "Linking dotfiles"

  local machine=$(machine_name)
  local machine_dir="$DOTFILES_DIR/$machine"

  if [ ! -d "$machine_dir" ]; then
    warn "The dotfiles have no folder for the machine '$machine' ($machine_dir). Exiting."
    exit 1
  fi

  info "Linking the folder '$machine' into $HOME"
  stow -v -d "$DOTFILES_DIR" -t "$HOME" "$machine" || {
    warn "Failed to link the folder '$machine'. Resolve any conflicting files at the target, then re-run."
    exit 1
  }

  success "Dotfiles linked."
}

install_homebrew_packages() {
  header "Installing Homebrew packages from Brewfile"

  local brewfile="$DOTFILES_DIR/$(machine_name)/.config/homebrew/Brewfile"

  if [ -f "$brewfile" ]; then
    info "Installing the packages in $brewfile"
    brew bundle --file="$brewfile"
    success "Homebrew package installation complete"
  else
    warn "No Brewfile at $brewfile. Skipping."
  fi
}

set_system_settings() {
  header "Setting system settings"

  "$BOOTSTRAP_DIR/set_macos_defaults.sh"
  success "Finished macOS defaults"

  # Manual System Settings Configuration
  info "Manual Action Required: Configure System Settings"
  info "This applies to settings which cannot be configured via 'defaults' commands."
  prompt "Once you are done, press Enter to continue..."

  success "macOS settings applied and manual steps completed"
}

set_application_settings() {
  header "Setting application settings"

  info "Manual Action Required: Configure Application Settings"
  info "Search for 'Application Settings' in RemNote for the details."
  info ""
  # TODO: move these instructions to RemNote under "Application Settings"
  info "Dock → 'All Desktops' (right-click app icon → Options → All Desktops):"
  info "  - KeePassXC  (keeps it accessible from any Space; fixes auto-type across Spaces)"
  info "  - Apple Notes  (quick capture from any Space)"
  info "  - Reminders  (surface reminders without Space-switching)"
  prompt "Once you are done, press Enter to continue..."
  success "Finished application settings"
}

# --- Main Execution ---

# Ensure the OS is a macOS
if [ "$(uname -s)" != "Darwin" ]; then
	warn "This script is only for macOS"
	exit 1
fi

bootstrap_env_folder # pull private files from icloud (e.g., git configuration)
ensure_github_ssh_access
setup_homebrew
clone_dotfiles
set_hostname
create_xdg_directories
link_dotfiles
install_homebrew_packages
set_system_settings
set_application_settings

header "DONE"
success "Bootstrap script completed successfully!"
