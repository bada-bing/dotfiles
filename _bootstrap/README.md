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

Runs its steps in order, pausing for manual confirmation where a step can't be automated. `setup_machine.sh --list` shows them, in order; each step says what it does as it runs. A step is named by its function, which is the name `--from` and `--to` take.

The whole script is meant to be safe to re-run: each step checks existing state before acting.

## Machine folders

Each machine has a folder of its own at the root of the dotfiles, named after its hostname and laid out as its home directory: `mini/.zshenv`, `mini/.config/zsh`, `mini/.config/homebrew/Brewfile`. A folder is a complete copy of that machine's configuration, so a change made on one machine stays there until it is copied to another. A folder with a leading underscore is not a machine.

Two more folders belong to each machine: `_bootstrap/<machine>/` holds what only the bootstrap reads (its settings and its list of repositories), and `private/env/<machine>/` holds its private configuration (its SSH config and its mise config).

## Running part of it

```sh
setup_machine.sh --list                                   # the steps, in order
setup_machine.sh --to set_hostname                        # from the start through `set_hostname`
setup_machine.sh --from link_dotfiles                     # from `link_dotfiles` to the end
setup_machine.sh --from link_dotfiles --to link_dotfiles  # only `link_dotfiles`
setup_machine.sh --dry-run                                # print what would change, change nothing
```

Both ends include the named step. An unknown step, or a `--to` that comes before the `--from`, is refused before any step runs.

`--dry-run` prints every command that would change the machine instead of running it. It still asks for values, such as the hostname, since what it prints depends on them, and it does not wait at the prompts that only wait for a manual action.
