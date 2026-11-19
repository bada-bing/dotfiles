# rex has to be on the PATH of a non-interactive shell, since ssh:// hosts of Rex run it without a login shell
export PATH="$HOME/.local/bin:$PATH"

# mise reads the Mac mini's own config, in its folder of the private configuration
export MISE_CONFIG_DIR="$HOME/Developer/toolbox/private/env/mini/mise"
