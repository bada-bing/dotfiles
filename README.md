`stow -S home` add $HOME symlinks
`stow -S -t ~/.config config` add CONFIG symlinks
`stow -D -t ~/.config config` remove CONFIG symlinks


IMPORTANT 2 folders and 1 file need to be manually sym-linked from LOCAL_ENV_DIR
- `ln -s $LOCAL_ENV_DIR/tmuxinator ~/.config/tmuxinator`
  - TODO hopefully there will be better solution once I create a generic tmuxinator project
- `ln -s $LOCAL_ENV_DIR/mprocs ~/.config/mprocs`
- `ln -s $LOCAL_ENV_DIR/mise.toml ~/.config/mise.toml`

TODO should the name be config or .config (of the folder)