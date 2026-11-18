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
PRIVATE_DIR="$HOME/Developer/toolbox/private"
ICLOUD_PRIVATE_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/BAK/toolbox/private" # the central copy of PRIVATE_DIR

# --- State ---
DRY_RUN=false
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

would_run() {
  echo -e "  ${C_YELLOW}would run:${C_RESET} ${1}"
}

prompt() {
  # The space after the prompt is intentional for better readability
  read -p "  _ ${1} " "${@:2}"
}

prompt_secret() {
  read -s -p "  _ ${1} " "${@:2}"
}

# Waits for Enter after a manual action. A dry run does not wait.
pause() {
  if [ "$DRY_RUN" = true ]; then
    info "(dry run, not waiting) ${1}"
  else
    prompt "${1}"
  fi
}

# Runs a command that changes the machine. A dry run prints it instead.
run() {
  if [ "$DRY_RUN" = true ]; then
    would_run "$(printf '%q ' "$@")"
  else
    "$@"
  fi
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

# Lists every file under a folder as "<path> <size> <modified>", relative to the folder.
# stat reads the size from the file's metadata, so a file iCloud has not downloaded yet counts at its real size.
list_files() {
  (cd "$1" && find . -type f ! -name .DS_Store -exec stat -f '%N %z %Sm' -t '%Y-%m-%d %H:%M' {} + | sort)
}

restore_private_env() {
  if [ ! -d "$ICLOUD_PRIVATE_DIR" ]; then
    warn "The iCloud backup of the private folder is not at '$ICLOUD_PRIVATE_DIR'. Exiting."
    exit 1
  fi

  if [ -d "$PRIVATE_DIR" ]; then
    # The backup in iCloud is the central copy; the local folder has to match it file by file.
    local differences
    differences=$(diff <(list_files "$PRIVATE_DIR") <(list_files "$ICLOUD_PRIVATE_DIR") || true)

    if [ -n "$differences" ]; then
      warn "toolbox/private differs from the iCloud backup (< local, > iCloud):"
      echo "$differences" | grep '^[<>]' | head -20 | sed 's/^/      /'
      warn "Reconcile the differences manually. Exiting."
      exit 1
    fi
    success "toolbox/private matches the iCloud backup."
  else
    info "The toolbox/private folder is missing. It should be restored from the iCloud backup."
    echo "Run the following command to restore it:"
    echo
    echo "mkdir -p \"$PRIVATE_DIR\""
    echo "cp -a \"$ICLOUD_PRIVATE_DIR/.\" \"$PRIVATE_DIR/\""
    echo
    pause "After running the command (or if you want to skip), press Enter to continue the setup script..."
  fi
}

setup_github_ssh() {
  local key_path="$HOME/.ssh/id_ed25519"
  local new_key_generated=false

  # Ensure .ssh directory exists
  if [ ! -d "$HOME/.ssh" ]; then
    run mkdir -p "$HOME/.ssh"
  fi
  run chmod 700 "$HOME/.ssh"

  if [ ! -f "$key_path" ]; then
    info "No SSH key found. Generating a new one."

    if [ "$DRY_RUN" = true ]; then
      run ssh-keygen -t ed25519 -C "<your GitHub email>" -f "$key_path" -N "<passphrase>"
    else
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
    fi
    new_key_generated=true

    success "New SSH key generated."
  else
    info "Existing SSH key found at $key_path."
  fi

  info "Ensuring ssh-agent is running and key is added to keychain..."
  # The `ssh-add -l` command will return a non-zero exit code if the agent is not running.
  if ! ssh-add -l &> /dev/null; then
    info "ssh-agent not running. Starting a new one for this script session..."
    if [ "$DRY_RUN" = true ]; then
      would_run "eval \"\$(ssh-agent -s)\""
    else
      eval "$(ssh-agent -s)"
    fi
  fi

  # Add the key to the agent if it's not already loaded.
  # We check for the key's filename in the output of ssh-add -l.
  if ! ssh-add -l | grep -q "id_ed25519"; then
    info "Adding SSH identity to the agent..."
    run ssh-add --apple-use-keychain "$key_path"
  else
    info "SSH identity is already loaded in the agent."
  fi

  if [ "$new_key_generated" = true ]; then
    if [ "$DRY_RUN" = true ]; then
      would_run "pbcopy < ${key_path}.pub"
    else
      pbcopy < "${key_path}.pub"
    fi
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
  pause "Press Enter to continue once your SSH key is configured on GitHub."

  # accept-new adds GitHub's host key to known_hosts; a dry run only checks against the keys already known.
  local host_key_checking="accept-new"
  if [ "$DRY_RUN" = true ]; then
    host_key_checking="yes"
  fi

  info "Verifying SSH connection to GitHub..."
  # The 2>&1 redirects stderr to stdout to grep the success message
  if ssh -o StrictHostKeyChecking="$host_key_checking" -T git@github.com < /dev/null 2>&1 | grep -q "successfully authenticated"; then
    success "GitHub SSH connection successful."
  else
    warn "Could not verify GitHub SSH connection. The script will continue, but you may face issues with private repositories."
  fi
}

install_homebrew() {
  # Check for Homebrew and install it if necessary
  if ! command -v brew &> /dev/null; then
    info "Installing Homebrew"
    if [ "$DRY_RUN" = true ]; then
      would_run "the Homebrew install script, https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
    else
      # The brew installation script takes care of Xcode Command Line Tools (CLT)
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

      # Ensure Homebrew is in the PATH for the current script execution
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  else
    info "Homebrew is already installed. Updating"
    run brew update # ensure latest formula/cask metadata before `brew bundle`
  fi

  if ! command -v stow &> /dev/null; then
    info "Installing GNU Stow (required to symlink dotfiles)"
    run brew install stow
  fi

  success "Homebrew setup complete"
}

clone_dotfiles() {
  if ! command -v git &> /dev/null; then
    warn "Git not found. It comes with the Xcode Command Line Tools, which the Homebrew installation installs."
    exit 1
  fi

  if [ -d "$DOTFILES_DIR" ]; then
    info "Dotfiles directory '$DOTFILES_DIR' already exists. Pulling latest changes."
    run git -C "$DOTFILES_DIR" pull || { warn "Failed to pull dotfiles updates."; exit 1; }
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
    run git clone "$DOTFILES_URL" "$DOTFILES_DIR" || { warn "Failed to clone dotfiles repository."; exit 1; }
  fi

  success "Dotfiles are in $DOTFILES_DIR"
}

set_hostname() {
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
    run sudo scutil --set LocalHostName "$new_hostname"
    run sudo scutil --set ComputerName "$new_hostname"
    run sudo scutil --set HostName "$new_hostname"
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

create_xdg_dirs() {
  # related: https://stackoverflow.com/questions/3373948/equivalents-of-xdg-config-home-and-xdg-data-home-on-mac-os-x
  # Created before the dotfiles are linked: stow links a missing ~/.config as one symlink into the
  # repository, and every file a tool writes there would then land in the dotfiles.
  for dir in "$HOME/.config" "$HOME/.local/share" "$HOME/.cache"; do
    if [ -d "$dir" ]; then
      info "Directory $dir already exists."
    else
      run mkdir -p "$dir"
      info "Created directory $dir."
    fi
  done

  success "XDG directories check complete."
}

link_dotfiles() {
  local machine=$(machine_name)
  local machine_dir="$DOTFILES_DIR/$machine"

  if [ ! -d "$machine_dir" ]; then
    warn "The dotfiles have no folder for the machine '$machine' ($machine_dir). Exiting."
    exit 1
  fi

  # The check after linking reads git, so the folder has to start out as committed.
  if [ -n "$(git -C "$DOTFILES_DIR" status --porcelain -- "$machine")" ]; then
    warn "The folder '$machine' has uncommitted changes. Commit or discard them, then re-run. Exiting."
    exit 1
  fi

  # --adopt moves a file already in place into the machine's folder and links it back,
  # so a file in the way is kept instead of refused, and git shows whether it differed.
  info "Linking the folder '$machine' into $HOME"
  run stow -v --adopt -d "$DOTFILES_DIR" -t "$HOME" "$machine" || {
    warn "Failed to link the folder '$machine'. Exiting."
    exit 1
  }

  local differing
  differing=$(git -C "$DOTFILES_DIR" status --porcelain -- "$machine")
  if [ -n "$differing" ]; then
    warn "Files already on this machine replaced their versions in the folder '$machine':"
    echo "$differing" | sed 's/^/      /'
    info "See what differs:          git -C $DOTFILES_DIR diff -- $machine"
    info "Keep this machine's files: commit them"
    info "Keep the dotfiles' files:  git -C $DOTFILES_DIR restore -- $machine"
    warn "Then re-run. Exiting."
    exit 1
  fi

  success "Dotfiles linked."
}

install_packages() {
  local brewfile="$DOTFILES_DIR/$(machine_name)/.config/homebrew/Brewfile"

  if [ -f "$brewfile" ]; then
    info "Installing the packages in $brewfile"
    run brew bundle --file="$brewfile"
    success "Homebrew package installation complete"
  else
    warn "No Brewfile at $brewfile. Skipping."
  fi
}

set_system_settings() {
  run "$BOOTSTRAP_DIR/set_macos_defaults.sh"
  success "Finished macOS defaults"

  # Manual System Settings Configuration
  info "Manual Action Required: Configure System Settings"
  info "This applies to settings which cannot be configured via 'defaults' commands."
  pause "Once you are done, press Enter to continue..."

  success "macOS settings applied and manual steps completed"
}

set_app_settings() {
  info "Manual Action Required: Configure Application Settings"
  info "Search for 'Application Settings' in RemNote for the details."
  info ""
  # TODO: move these instructions to RemNote under "Application Settings"
  info "Dock → 'All Desktops' (right-click app icon → Options → All Desktops):"
  info "  - KeePassXC  (keeps it accessible from any Space; fixes auto-type across Spaces)"
  info "  - Apple Notes  (quick capture from any Space)"
  info "  - Reminders  (surface reminders without Space-switching)"
  pause "Once you are done, press Enter to continue..."
  success "Finished application settings"
}

# --- Running the steps ---

# The steps, in the order they run. Each is the function of that name.
STEPS=(
  restore_private_env # pull private files from icloud (e.g., git configuration)
  setup_github_ssh
  install_homebrew
  clone_dotfiles
  set_hostname
  create_xdg_dirs
  link_dotfiles
  install_packages
  set_system_settings
  set_app_settings
)

usage() {
  echo "Usage: setup_machine.sh [--from <step>] [--to <step>] [--dry-run] [--list]"
  echo
  echo "Runs the steps in order, all of them by default."
  echo "  --from <step>  start at this step"
  echo "  --to <step>    stop after this step"
  echo "  --dry-run      print the commands that would change the machine instead of running them"
  echo "  --list         show the steps, in order"
  echo
  echo "Both ends include the named step, so --from x --to x runs only x."
}

die() {
  echo -e "error: ${1}" >&2
  exit 1
}

list_steps() {
  local i
  for i in "${!STEPS[@]}"; do
    printf "  %2d) %s\n" "$((i + 1))" "${STEPS[$i]}"
  done
}

# Prints the position of a step, counting from 1, or nothing when there is no such step.
step_index() {
  local i
  for i in "${!STEPS[@]}"; do
    if [ "${STEPS[$i]}" = "$1" ]; then
      echo "$((i + 1))"
      return
    fi
  done
}

# Sets FROM_INDEX, TO_INDEX and DRY_RUN, refusing an unknown step or a reversed range.
parse_args() {
  local from_step="" to_step=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --from)
        [ -n "${2:-}" ] || die "--from needs a step. Run --list to see the steps."
        from_step="$2"
        shift 2
        ;;
      --to)
        [ -n "${2:-}" ] || die "--to needs a step. Run --list to see the steps."
        to_step="$2"
        shift 2
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --list)
        list_steps
        exit 0
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "unknown argument '$1'. Run --help for the usage."
        ;;
    esac
  done

  FROM_INDEX=1
  TO_INDEX=${#STEPS[@]}

  if [ -n "$from_step" ]; then
    FROM_INDEX=$(step_index "$from_step")
    [ -n "$FROM_INDEX" ] || die "unknown step '$from_step'. Run --list to see the steps."
  fi

  if [ -n "$to_step" ]; then
    TO_INDEX=$(step_index "$to_step")
    [ -n "$TO_INDEX" ] || die "unknown step '$to_step'. Run --list to see the steps."
  fi

  if [ "$TO_INDEX" -lt "$FROM_INDEX" ]; then
    die "--to $to_step ($TO_INDEX) comes before --from $from_step ($FROM_INDEX). Run --list to see the order."
  fi
}

run_steps() {
  local i step
  for i in "${!STEPS[@]}"; do
    step="${STEPS[$i]}"
    if [ "$((i + 1))" -ge "$FROM_INDEX" ] && [ "$((i + 1))" -le "$TO_INDEX" ]; then
      header "$((i + 1))/${#STEPS[@]} $step"
      "$step"
    fi
  done
}

# --- Main Execution ---

parse_args "$@"

# Ensure the OS is a macOS
if [ "$(uname -s)" != "Darwin" ]; then
	warn "This script is only for macOS"
	exit 1
fi

if [ "$DRY_RUN" = true ]; then
  header "DRY RUN: nothing on this machine is changed"
fi

run_steps

header "DONE"
if [ "$FROM_INDEX" -eq 1 ] && [ "$TO_INDEX" -eq ${#STEPS[@]} ]; then
  success "Bootstrap script completed successfully!"
else
  success "Finished steps ${FROM_INDEX} to ${TO_INDEX}."
fi
