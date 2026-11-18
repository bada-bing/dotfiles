# dotfiles

## Machine Setup Procedure

For instructions on setting up a macOS machine, refer to the [Machine Setup Procedure in `_bootstrap/README.md`](./_bootstrap/README.md).

## Repository Structure

- **`.config/`**: Tool-specific configurations (e.g., Neovim, Tmux, Sketchybar, Ghostty). Symlinked to `~/.config/`.
- **`home/`**: Dotfiles intended for the root of the home directory (e.g., `.zprofile`, `.taskrc`).
- **`_bootstrap/`**: Scripts and configurations for initial machine setup, macOS defaults, and `Brewfile` package management.
- **`_archive/`**: Retired or experimental configurations kept for reference.

---

## Per-Machine Configuration

Each machine has a folder of its own at the root, named after its hostname and laid out as its home directory, such as `mini/`. `_bootstrap/setup_machine.sh` links it with `stow -t ~ <machine>`. See [Machine folders in `_bootstrap/README.md`](./_bootstrap/README.md#machine-folders).

---

## Symlinking (Stow)

To symlink `.config` and `home` manually:

`cd ~/Developer/toolbox/dotfiles;` ensure you run Stow commands from the `dotfiles` dir

`stow -t ~ home` add $HOME symlinks
`stow -t ~/.config .config` add CONFIG symlinks

In case you need to remove the symlinks:
`stow -D -t ~ home` remove $HOME symlinks
`stow -D -t ~/.config .config` remove CONFIG symlinks