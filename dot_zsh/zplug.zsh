system_type=$(uname -s)

if [ "$system_type" = "Darwin" ]; then
  source $(brew --prefix zplug)/init.zsh
elif [ "$system_type" = "Linux" ]; then
  # More concretely, this works on Arch / Manjaro. Unclear for other Linux flavors.
  source /usr/share/zsh/scripts/zplug/init.zsh
else
  echo "zplug: UNKNOWN SYSTEM: $(uname -a)"
fi

zplug "bigH/git-fuzzy", as:command, use:"bin/git-fuzzy"

# zplug install
# zplug update
zplug load
