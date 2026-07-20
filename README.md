# dotfiles

## Machine Setup Procedure

For instructions on setting up a macOS machine, refer to the [Machine Setup Procedure in `_bootstrap/README.md`](./_bootstrap/README.md).

## Repository Structure

- **`.config/`**: Tool-specific configurations (e.g., Neovim, Tmux, Sketchybar, Ghostty). Symlinked to `~/.config/`.
- **`home/`**: Dotfiles intended for the root of the home directory (e.g., `.zprofile`, `.taskrc`).
- **`_bootstrap/`**: Scripts and configurations for initial machine setup, macOS defaults, and `Brewfile` package management.
- **`_archive/`**: Retired or experimental configurations kept for reference.

---

## Per-Machine Divergence

> [!NOTE]
> If a machine needs to diverge from the shared dotfiles (e.g. a simpler Neovim config, no custom
> statusbar), create a branch for it (e.g. `custom`) and add a `hostname=branch` line to
> [`_bootstrap/machine-branches.txt`](./_bootstrap/machine-branches.txt) **on `main`** — that's what
> makes every clone aware of the mapping. `setup_machine.sh` reads it and switches branches by
> hostname automatically, so there's nothing to remember by hand. Rebase the branch onto `main`
> periodically to stay in sync, and delete it (and its mapping line) once the divergence is no
> longer needed.

---

## Symlinking (Stow)

`_bootstrap/setup_machine.sh` runs this automatically. To symlink manually:

`cd ~/Developer/toolbox/dotfiles;` ensure you run Stow commands from the `dotfiles` dir

`stow -t ~ home` add $HOME symlinks
`stow -t ~/.config .config` add CONFIG symlinks

In case you need to remove the symlinks:
`stow -D -t ~ home` remove $HOME symlinks
`stow -D -t ~/.config .config` remove CONFIG symlinks