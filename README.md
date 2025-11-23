`cd ~/dotfiles;` before you start go to dotfiles dir

`stow -S home` add $HOME symlinks (-S is default option, means symlink and is not necessary)
`stow -S -t ~/.config .config` add CONFIG symlinks

In case you need to remove the symlinks:
`stow -D home` remove CONFIG symlinks
`stow -D -t ~/.config .config` remove CONFIG symlinks


