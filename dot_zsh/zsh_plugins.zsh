if is_macos; then
  zsh_plugins="$HOME/.oh-my-zsh/custom/plugins"
elif is_linux; then
  zsh_plugins="/usr/share/zsh/plugins"
else
  echo "UNKNOWN SYSTEM: $(uname -a)"
fi

if [[ -f $zsh_plugins/fzf-tab/fzf-tab.plugin.zsh ]]; then
  source $zsh_plugins/fzf-tab/fzf-tab.plugin.zsh
elif [[ -f $zsh_plugins/fzf-tab-git/fzf-tab.plugin.zsh ]]; then
  source $zsh_plugins/fzf-tab-git/fzf-tab.plugin.zsh
fi

export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE='32'
export ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

source $zsh_plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source $zsh_plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
