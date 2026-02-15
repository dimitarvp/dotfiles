# disable ctrl+s, ctrl+q
setopt no_flow_control

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_TIME=en_US.UTF-8

setopt rm_star_silent

fpath+=${ZDOTDIR:-$HOME}/.zsh_functions

# Suggest from history first, then from completion engine.
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Word navigation keybindings (cross-terminal: Alacritty, Ghostty, iTerm2)
# Alt+Arrow for word navigation - bind multiple escape sequences for compatibility
bindkey '^[[1;3D' backward-word      # Alt+Left (xterm-style, most terminals)
bindkey '^[[1;3C' forward-word       # Alt+Right (xterm-style, most terminals)
bindkey '^[^[[D' backward-word       # ESC+Left (fallback)
bindkey '^[^[[C' forward-word        # ESC+Right (fallback)

# Word deletion
bindkey '^[^?' backward-kill-word    # Alt+Backspace
bindkey '^[[3;5~' kill-word          # Ctrl+Delete
