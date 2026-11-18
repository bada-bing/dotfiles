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

Runs the following steps in order, pausing for manual confirmation where a step can't be automated. Each step is named by its function, which is the name `--from` and `--to` take.

1. **`restore_private_env`** — checks `~/Developer/toolbox/private/env` is present; if not, prompts to restore it from the iCloud `BAK` backup.
2. **`setup_github_ssh`** — generates an SSH key if none exists, loads it into the keychain, and verifies GitHub SSH access.
3. **`install_homebrew`** — installs Homebrew (and Xcode CLT) if missing, then installs `stow`, which linking the dotfiles needs.
4. **`clone_dotfiles`** — clones this repo to `~/Developer/toolbox/dotfiles`, or pulls it when it is already there.
5. **`set_hostname`** — reconciles `ComputerName`/`LocalHostName`/`HostName` and offers the machines that have a folder in the dotfiles. The hostname names the machine's folder.
6. **`create_xdg_dirs`** — ensures `~/.config`, `~/.local/share`, `~/.cache` exist, before anything is linked into them.
7. **`link_dotfiles`** — links the machine's folder into the home directory: `stow -t ~ <machine>`.
8. **`install_packages`** — runs `brew bundle` against the machine's Brewfile, `<machine>/.config/homebrew/Brewfile`.
9. **`set_system_settings`** — applies `set_macos_defaults.sh`, then prompts for manual System Settings changes that can't be scripted.
10. **`set_app_settings`** — prompts for manual per-app settings (documented in RemNote, plus a few noted directly in the script).

The whole script is meant to be safe to re-run: each step checks existing state before acting.

## Machine folders

Each machine has a folder of its own at the root of the dotfiles, named after its hostname and laid out as its home directory: `mini/.zshenv`, `mini/.config/zsh`, `mini/.config/homebrew/Brewfile`. A folder is a complete copy of that machine's configuration, so a change made on one machine stays there until it is copied to another. A folder with a leading underscore is not a machine.

## Running part of it

```sh
setup_machine.sh --list                                   # the steps, in order
setup_machine.sh --to set_hostname                        # from the start through `set_hostname`
setup_machine.sh --from link_dotfiles                     # from `link_dotfiles` to the end
setup_machine.sh --from link_dotfiles --to link_dotfiles  # only `link_dotfiles`
```

Both ends include the named step. An unknown step, or a `--to` that comes before the `--from`, is refused before any step runs.
