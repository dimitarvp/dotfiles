source $HOME/.oh-my-zsh/custom/plugins/fzf-tab/fzf-tab.plugin.zsh

if is_macos; then
  zsh_plugins="$HOME/.oh-my-zsh/custom/plugins"
elif is_linux; then
  zsh_plugins="/usr/share/zsh/plugins"
else
  echo "UNKNOWN SYSTEM: $(uname -a)"
fi

export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE='32'
export ZSH_AUTOSUGGEST_USE_ASYNC=1

source $zsh_plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source $zsh_plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
