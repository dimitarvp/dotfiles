# disable ctrl+s, ctrl+q
setopt no_flow_control

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
HIST_STAMPS="yyyy-mm-dd"

export LOCALE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_TIME=en_US.UTF-8

autoload -Uz compinit
compinit

fpath+=${ZDOTDIR:-$HOME}/.zsh_functions

# Uncomment this to enable `fzf` completion when pressing TAB.
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
