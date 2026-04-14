export FZF_DEFAULT_OPTS='--inline-info --bind ctrl-f:preview-page-down,ctrl-b:preview-page-up'

export FZF_DEFAULT_COMMAND='fd -t f --strip-cwd-prefix'

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

export FZF_CTRL_T_OPTS="
  --height 100%
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

export FZF_ALT_C_COMMAND='fd -t d'
export FZF_ALT_C_OPTS="--preview 'tree -C {}'"

# Use fd (https://github.com/sharkdp/fd) instead of the default find
# command for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --follow --exclude ".git" . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude ".git" . "$1"
}

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'tree -C {} | head -200'   "$@" ;;
    export|unset) fzf --preview "eval 'echo \$'{}"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview 'bat -n --color=always {}' "$@" ;;
  esac
}

fzf_find_git_uncommitted() {
    git rev-parse --is-inside-work-tree &>/dev/null || { zle redisplay; return; }
    local selected_entry
    selected_entry=$(git_changed | fzf --select-1 --layout reverse --prompt 'GIT> ' --height 40% --highlight-line)
    if [[ -n "$selected_entry" ]]; then
        LBUFFER="${LBUFFER}${selected_entry}"
    fi
    zle reset-prompt
}
zle -N fzf_find_git_uncommitted
bindkey '^U' fzf_find_git_uncommitted

eval "$(fzf --zsh)"

# Unbind Esc-c (fzf default for Alt-C) — collides with Esc to dismiss fzf
# Rebind directory picker to Ctrl-O
bindkey -r '\ec'
bindkey '^O' fzf-cd-widget
