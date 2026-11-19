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
SRC_DIR="$HOME/Developer/src" # where clone_repositories clones a machine's repositories

# The user a machine has unless it is set up otherwise. Another one is allowed once confirmed.
DEFAULT_USER="miki"

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

# Reports an action as done. A dry run did not do it, and its "would run" line already says so.
success_if_done() {
  if [ "$DRY_RUN" != true ]; then
    success "${1}"
  fi
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

# What the bootstrap reads for this machine alone: its settings and its list of repositories.
machine_bootstrap_dir() {
  echo "$BOOTSTRAP_DIR/$(machine_name)"
}

# The machine's own folder in the private configuration: its SSH config, its mise config.
machine_private_dir() {
  echo "$PRIVATE_DIR/env/$(machine_name)"
}

# Warns when the user is not DEFAULT_USER and asks whether to go on, refusing only on no.
# What was set up by hand against the default home, such as a link of rex, would not match.
check_user() {
  local user
  user=$(whoami)
  if [ "$user" = "$DEFAULT_USER" ]; then
    return
  fi

  warn "The user is '$user', not the default user '$DEFAULT_USER'."
  info "The script works from \$HOME, but what was set up by hand against /Users/$DEFAULT_USER will not match."
  if [ "$DRY_RUN" = true ]; then
    return
  fi

  prompt "Continue as '$user'? [Y/n]" -n 1 -r REPLY
  echo
  if [[ $REPLY =~ ^[Nn]$ ]]; then
    warn "Exiting."
    exit 1
  fi
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

# Links the machine's SSH config and makes sure the machine has its one key, id_ed25519.
# The key reaches everything the machine connects to, and its comment names the machine.
setup_ssh() {
  local machine
  machine=$(machine_name)
  local key_path="$HOME/.ssh/id_ed25519"
  local ssh_config
  ssh_config="$(machine_private_dir)/ssh/config"

  if [ ! -f "$ssh_config" ]; then
    warn "The machine '$machine' has no SSH config at $ssh_config."
    warn "Write it in the private folder on the MacBook and refresh the iCloud backup. Exiting."
    exit 1
  fi

  if [ ! -d "$HOME/.ssh" ]; then
    run mkdir -p "$HOME/.ssh"
  fi
  run chmod 700 "$HOME/.ssh"

  # The SSH config is the machine's own, kept in the private folder; ~/.ssh/config links to it.
  if [ -L "$HOME/.ssh/config" ] && [ "$(readlink "$HOME/.ssh/config")" = "$ssh_config" ]; then
    info "~/.ssh/config already links to $ssh_config"
  else
    if [ -e "$HOME/.ssh/config" ] || [ -L "$HOME/.ssh/config" ]; then
      if ! cmp -s "$HOME/.ssh/config" "$ssh_config"; then
        warn "~/.ssh/config differs from $ssh_config (< this machine, > private):"
        diff "$HOME/.ssh/config" "$ssh_config" | grep '^[<>]' | sed 's/^/      /' || true
      fi
      info "Keeping the old one as ~/.ssh/config.before-bootstrap"
      run mv "$HOME/.ssh/config" "$HOME/.ssh/config.before-bootstrap"
    fi
    run ln -s "$ssh_config" "$HOME/.ssh/config"
    success_if_done "~/.ssh/config links to $ssh_config"
  fi

  local comment
  comment="$(whoami)@$machine"

  # An existing key is kept, never replaced: a key is not backed up, so replacing one is decided by hand.
  if [ -f "$key_path" ]; then
    local existing_comment fingerprint
    existing_comment=$(cut -d' ' -f3- "$key_path.pub" 2>/dev/null)
    fingerprint=$(ssh-keygen -lf "$key_path.pub" 2>/dev/null | awk '{print $2}')
    info "The machine already has a key, $key_path, and it is kept."
    info "  comment:     ${existing_comment:-none}"
    info "  fingerprint: ${fingerprint:-unreadable}"
    if [ "$existing_comment" != "$comment" ]; then
      warn "Its comment is not '$comment', so it was not made by this step."
      info "To replace it, remove it from GitHub and from the authorized_keys of other machines, delete $key_path and $key_path.pub, then re-run this step."
    fi
    return
  fi

  info "Generating the key of the machine, $key_path, with the comment '$comment'."
  if [ "$DRY_RUN" = true ]; then
    run ssh-keygen -t ed25519 -C "$comment" -f "$key_path" -N "<passphrase>"
    return
  fi

  local passphrase="" passphrase_confirm=""
  while true; do
    prompt_secret "Enter a passphrase for the key:" passphrase
    echo
    if [ -z "$passphrase" ]; then
      warn "The key has a passphrase. Please enter one."
      continue
    fi
    prompt_secret "Confirm the passphrase:" passphrase_confirm
    echo
    if [ "$passphrase" = "$passphrase_confirm" ]; then
      break
    fi
    warn "The passphrases do not match. Please try again."
  done
  ssh-keygen -t ed25519 -C "$comment" -f "$key_path" -N "$passphrase"
  success "Generated $key_path."
}

# Prints whether GitHub accepts the machine's key. IdentitiesOnly offers this key alone,
# so a forwarded agent cannot make the check pass with another machine's key.
github_accepts_key() {
  local host_key_checking="$1"
  ssh -o StrictHostKeyChecking="$host_key_checking" -o IdentitiesOnly=yes -i "$HOME/.ssh/id_ed25519" \
    -T git@github.com < /dev/null 2>&1 | grep -q "successfully authenticated"
}

# Checks that GitHub accepts the machine's key, and shows how to add it there when it does not.
connect_github() {
  local machine
  machine=$(machine_name)
  local key_path="$HOME/.ssh/id_ed25519"

  if [ ! -f "$key_path" ]; then
    if [ "$DRY_RUN" = true ]; then
      info "The machine has no key yet; setup_ssh generates it."
      return
    fi
    warn "The machine has no key at $key_path. Run the step setup_ssh first. Exiting."
    exit 1
  fi

  # The first use asks for the passphrase, which the keychain keeps from then on.
  # Over plain SSH the keychain is out of reach, so the check could not tell a missing key from a locked one.
  if [ -n "${SSH_CONNECTION:-}" ]; then
    if [ "$DRY_RUN" = true ]; then
      info "Over plain SSH the keychain cannot be read, so the connection to GitHub is not checked."
      return
    fi
    warn "This step runs in the session of the user: in a tab of Rex, or at the machine. Over plain SSH the keychain cannot be read. Exiting."
    exit 1
  fi

  # accept-new adds GitHub's host key to known_hosts; a dry run only checks against the keys already known.
  local host_key_checking="accept-new"
  if [ "$DRY_RUN" = true ]; then
    host_key_checking="yes"
  fi

  info "Checking the connection to GitHub with $key_path..."
  if github_accepts_key "$host_key_checking"; then
    success "Connected to GitHub over SSH."
    return
  fi

  if [ "$DRY_RUN" = true ]; then
    info "GitHub does not accept the key yet; a real run shows how to add it."
    return
  fi

  # Printed as well as copied: in a tab of Rex the clipboard is the machine's, not the one in front of you.
  pbcopy < "$key_path.pub"
  info "GitHub does not accept the key yet. Add it: it is on the clipboard of this machine, and here:"
  echo
  echo "    $(cat "$key_path.pub")"
  echo
  info "1. Open https://github.com/settings/ssh/new"
  info "2. Title: $machine"
  info "3. Key: paste the line above"
  info "4. Click 'Add SSH key'"
  pause "Press Enter once the key is on GitHub."

  if github_accepts_key "$host_key_checking"; then
    success "Connected to GitHub over SSH."
  else
    warn "Could not connect to GitHub over SSH. A private repository cannot be cloned until it does."
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

  success_if_done "Homebrew setup complete"
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

  success_if_done "Dotfiles are in $DOTFILES_DIR"
}

set_hostname() {
  local computer_name=$(scutil --get ComputerName)
  local local_host_name=$(scutil --get LocalHostName)
  local host_name=$(scutil --get HostName 2>/dev/null || echo "not set")

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

  # Choosing the name the machine already has in all three places changes nothing, so it needs no sudo.
  if [ -n "$new_hostname" ] && [ "$new_hostname" = "$computer_name" ] && [ "$new_hostname" = "$local_host_name" ] && [ "$new_hostname" = "$host_name" ]; then
    MACHINE="$new_hostname"
    success "Hostname is already $new_hostname"
  elif [ -n "$new_hostname" ]; then
    info "Setting hostname to $new_hostname"
    run sudo scutil --set LocalHostName "$new_hostname"
    run sudo scutil --set ComputerName "$new_hostname"
    run sudo scutil --set HostName "$new_hostname"
    MACHINE="$new_hostname"
    success_if_done "Hostname set to $new_hostname"
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
      success_if_done "Created directory $dir."
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

  success_if_done "Dotfiles linked."
}

install_brew_packages() {
  local brewfile="$DOTFILES_DIR/$(machine_name)/.config/homebrew/Brewfile"

  if [ -f "$brewfile" ]; then
    info "Installing the packages in $brewfile"
    run brew bundle --file="$brewfile"
    success_if_done "Homebrew package installation complete"
  else
    warn "No Brewfile at $brewfile. Skipping."
  fi
}

# Installs the tools of the machine's mise config. mise installs a missing tool on demand
# only in an interactive shell, so the shims that proc, SSH and scripts go through need it done here.
install_mise_tools() {
  local mise_dir
  mise_dir="$(machine_private_dir)/mise"

  if [ ! -f "$mise_dir/config.toml" ]; then
    warn "No mise config at $mise_dir/config.toml. Skipping."
    return
  fi

  if ! command -v mise &> /dev/null; then
    if [ "$DRY_RUN" = true ]; then
      info "mise is not installed yet; install_brew_packages installs it from the machine's Brewfile."
    else
      warn "mise is not installed. It comes from the machine's Brewfile, through install_brew_packages. Exiting."
      exit 1
    fi
  fi

  # Run from $HOME, so no project's mise.toml joins the machine's config.
  info "Installing the tools in $mise_dir/config.toml"
  run env MISE_CONFIG_DIR="$mise_dir" mise install -C "$HOME"
  success_if_done "Tools installed"
}

# Clones the machine's repositories into SRC_DIR, from the list in its bootstrap folder:
# one "<owner>/<name> [install command]" per line. A repository already there is left alone,
# and its install command runs only right after it is cloned, so a second run changes nothing.
clone_repositories() {
  local list
  list="$(machine_bootstrap_dir)/repositories"

  if [ ! -f "$list" ]; then
    warn "No list of repositories at $list. Skipping."
    return
  fi

  if [ ! -d "$SRC_DIR" ]; then
    run mkdir -p "$SRC_DIR"
  fi

  local mise_dir
  mise_dir="$(machine_private_dir)/mise"

  local repo command dir
  # Read from fd 3, so git and ssh keep the terminal for a passphrase.
  while read -r repo command <&3; do
    [[ -z "$repo" || "$repo" == \#* ]] && continue
    dir="$SRC_DIR/$(basename "$repo")"

    if [ -d "$dir" ]; then
      info "$repo is already in $dir"
      continue
    fi

    info "Cloning $repo into $dir"
    run git clone "git@github.com:$repo.git" "$dir"

    if [ -n "$command" ]; then
      info "Installing $repo: $command"
      # mise exec puts the tools of the machine's mise config on the PATH, such as Go for a build.
      run env MISE_CONFIG_DIR="$mise_dir" mise exec -C "$dir" -- bash -c "$command"
    fi
    success_if_done "Cloned $repo"
  done 3< "$list"
}

# Applies the machine's macOS defaults, from its bootstrap folder.
set_system_settings() {
  local script
  script="$(machine_bootstrap_dir)/macos_defaults.sh"

  if [ ! -f "$script" ]; then
    warn "No macOS defaults at $script. Skipping."
    return
  fi

  info "Applying $script"
  run /bin/bash "$script"
  success_if_done "Finished macOS defaults"
}

# Shows the application settings the machine asks for by hand, from its bootstrap folder.
set_app_settings() {
  local file
  file="$(machine_bootstrap_dir)/app_settings.txt"

  if [ ! -s "$file" ]; then
    info "The machine '$(machine_name)' asks for no application settings."
    return
  fi

  info "Manual Action Required: Configure Application Settings"
  sed 's/^/    /' "$file"
  pause "Once you are done, press Enter to continue..."
  success_if_done "Finished application settings"
}

# --- Running the steps ---

# The steps, in the order they run. Each is the function of that name.
# setup_ssh and connect_github come after set_hostname, since the key's comment and title name the machine.
STEPS=(
  restore_private_env # pull private files from icloud (e.g., git configuration)
  install_homebrew
  clone_dotfiles
  set_hostname
  setup_ssh
  connect_github
  create_xdg_dirs
  link_dotfiles
  install_brew_packages
  install_mise_tools
  clone_repositories
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

check_user

run_steps

header "DONE"
if [ "$FROM_INDEX" -eq 1 ] && [ "$TO_INDEX" -eq ${#STEPS[@]} ]; then
  success "Bootstrap script completed successfully!"
else
  success "Finished steps ${FROM_INDEX} to ${TO_INDEX}."
fi
