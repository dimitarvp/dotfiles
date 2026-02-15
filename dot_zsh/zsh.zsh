# disable ctrl+s, ctrl+q
setopt no_flow_control

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
HIST_STAMPS="yyyy-mm-dd"

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_TIME=en_US.UTF-8

setopt rm_star_silent

# NOTE: compinit is handled by Oh-My-Zsh - don't call it here (causes double init, adds 100-300ms)

fpath+=${ZDOTDIR:-$HOME}/.zsh_functions

# Suggest from history first, then from completion engine.
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Update oh-my-zsh.
zstyle ':omz:update' mode auto

# Word navigation keybindings (cross-terminal: Alacritty, Ghostty, iTerm2)
# Alt+Arrow for word navigation - bind multiple escape sequences for compatibility
bindkey '^[[1;3D' backward-word      # Alt+Left (xterm-style, most terminals)
bindkey '^[[1;3C' forward-word       # Alt+Right (xterm-style, most terminals)
bindkey '^[^[[D' backward-word       # ESC+Left (fallback)
bindkey '^[^[[C' forward-word        # ESC+Right (fallback)

# Word deletion
bindkey '^[^?' backward-kill-word    # Alt+Backspace
bindkey '^[[3;5~' kill-word          # Ctrl+Delete
