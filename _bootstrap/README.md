# Machine Setup Procedure

It is designed to automate as much as possible while still keeping me in the loop. 
The script should guide the process, remind about required actions, and wait for confirmation before continuing.

Workflow on a new machine:

1. Sign into the Apple ID
2. Wait for iCloud Drive to synchronize
3. Open the `bootstrap_instructions.txt` stored in iCloud Drive (or in Apple Notes)
4. Copy the bootstrap command into the terminal
5. The bootstrap script takes over and guides the remaining setup process

## What `setup_machine.sh` does

Runs the following steps in order, pausing for manual confirmation where a step can't be automated:

1. **`bootstrap_env_folder`** — checks `~/Developer/toolbox/private/env` is present; if not, prompts to restore it from the iCloud `BAK` backup.
2. **`ensure_github_ssh_access`** — generates an SSH key if none exists, loads it into the keychain, and verifies GitHub SSH access.
3. **`set_hostname`** — reconciles `ComputerName`/`LocalHostName`/`HostName` and optionally sets a new one.
4. **`setup_homebrew`** — installs Homebrew (and Xcode CLT) if missing, then installs `stow` explicitly, since dotfiles symlinking needs it before the `Brewfile` bundle (below) has run.
5. **`setup_dotfiles`** — clones this repo to `~/Developer/toolbox/dotfiles` if not already present, then symlinks it via `stow -t ~/.config .config` and `stow -t ~ home` (see the [root README](../README.md#symlinking-stow)).
6. **`install_homebrew_packages`** — runs `brew bundle` against `Brewfile`, `Brewfile.utils`, `Brewfile.dev`, and `Brewfile.workstation`.
7. **`create_xdg_directories`** — ensures `~/.config`, `~/.local/share`, `~/.cache` exist.
8. **`set_system_settings`** — applies `set_macos_defaults.sh`, then prompts for manual System Settings changes that can't be scripted.
9. **`set_application_settings`** — prompts for manual per-app settings (documented in RemNote, plus a few noted directly in the script).

The whole script is meant to be safe to re-run: each step checks existing state before acting.