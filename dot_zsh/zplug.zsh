source $(brew --prefix zplug)/init.zsh

zplug "bigH/git-fuzzy", as:command, use:"bin/git-fuzzy"

zplug install
zplug update
zplug load
