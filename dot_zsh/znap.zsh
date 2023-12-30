znap_root_dir="$HOME/.znap"
znap_own_dir="$znap_root_dir/znap"

# Create Znap directory if it does not exist.
if [ ! -d $znap_root_dir ]; then
  mkdir $znap_root_dir
fi

# Download Znap, if it's not there yet.
[[ -r "$znap_own_dir/znap.zsh" ]] ||
    git clone -q --depth 1 -- \
        https://github.com/marlonrichert/zsh-snap.git $znap_own_dir

# Start Znap.
source "$znap_own_dir/znap.zsh"

# Plugins.
znap install 'bigH/git-fuzzy'

# Update Znap itself and all plugins.
znap pull
