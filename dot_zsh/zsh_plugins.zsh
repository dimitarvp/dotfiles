source $ZSH_CUSTOM/plugins/fzf-tab/fzf-tab.plugin.zsh

if [ "$system_type" = "Darwin" ]; then
  declare +r zsh_plugins="/usr/local/share"
elif [ "$system_type" = "Linux" ]; then
  declare +r zsh_plugins="/usr/share/zsh/plugins"
else
  echo "UNKNOWN SYSTEM: $(uname -a)"
fi

source $zsh_plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $zsh_plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
