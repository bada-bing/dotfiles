# dotfiles

## Bootstrapping

To set up a new macOS machine, run the bootstrap script from the dotfiles directory. The script is idempotent, meaning it can be run multiple times safely.

```sh
./_bootstrap/setup_machine.sh
```

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