export FZF_DEFAULT_OPTS='--inline-info --bind ctrl-f:preview-page-down,ctrl-b:preview-page-up'

export FZF_DEFAULT_COMMAND='fd -t f --strip-cwd-prefix'

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

export FZF_CTRL_T_OPTS="
  --height 100%
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

if is_macos; then
  _fzf_clip='pbcopy'
else
  _fzf_clip='wl-copy'
fi

export FZF_CTRL_R_OPTS="
  --preview 'echo {}' --preview-window up:3:hidden:wrap
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo -n {2..} | $_fzf_clip)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"

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

# fzf keybindings + completions — source from platform-specific paths.
# macOS (brew): /usr/local/opt/fzf/shell/ or /opt/homebrew/opt/fzf/shell/
# Linux (pacman): /usr/share/fzf/
local _fzf_shell="${HOMEBREW_PREFIX}/opt/fzf/shell"
if [[ -d $_fzf_shell ]]; then
  source "$_fzf_shell/key-bindings.zsh"
  source "$_fzf_shell/completion.zsh"
elif [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
  source /usr/share/fzf/completion.zsh
fi

# Unbind Esc-c (fzf default for Alt-C) — collides with Esc to dismiss fzf
# Rebind directory picker to Ctrl-O
bindkey -r '\ec'
bindkey '^O' fzf-cd-widget
