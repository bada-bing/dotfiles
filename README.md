# dotfiles

## Machine Setup Procedure

For instructions on setting up a macOS machine, refer to the [Machine Setup Procedure in `_bootstrap/README.md`](./_bootstrap/README.md).

---

## Manual Symlinking (Stow)

> [!NOTE]
> I am reconsidering if I really need Stow; the bootstrap script relies on simple `ln -s` for symlinking specific configurations. 

`cd ~/dotfiles;` ensure you run Stow commands from `/dotfiles` dir

`stow -S home` add $HOME symlinks (-S is default option, means symlink and is not necessary)
`stow -S -t ~/.config .config` add CONFIG symlinks

In case you need to remove the symlinks:
`stow -D home` remove CONFIG symlinks
`stow -D -t ~/.config .config` remove CONFIG symlinks