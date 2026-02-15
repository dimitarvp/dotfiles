DEFAULT_USER="dimi" # hides "user@host" when logged in as this user

export ZSH="$HOME/.oh-my-zsh"

DISABLE_AUTO_UPDATE="true"
COMPLETION_WAITING_DOTS="true"

plugins=(colored-man-pages colorize fzf httpie mix rsync rust)

export ZSH_COLORIZE_TOOL=chroma
export ZSH_COLORIZE_CHROMA_FORMATTER=terminal16m

# https://stackoverflow.com/a/71271754/285154
export ZSH_COMPDUMP=$ZSH/cache/.zcompdump-$HOST

source $ZSH/oh-my-zsh.sh
