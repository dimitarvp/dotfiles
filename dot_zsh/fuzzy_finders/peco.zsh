# ZSH widgets for invoking Peco (fuzzy finder) and their keybinds
# peco_find_file() {
#     local selected_path
#     selected_path=$(fd -t f | peco --prompt 'FILE>') || return
#     eval 'LBUFFER="$LBUFFER$selected_path"'
# }
# zle -N peco_find_file
# bindkey '^T' peco_find_file

# peco_find_dir() {
#     local selected_path
#     selected_path=$(fd -t d | peco --prompt 'DIR>') || return
#     eval 'LBUFFER="$LBUFFER$selected_path"'
# }
# zle -N peco_find_dir
# bindkey '^Y' peco_find_dir

# peco_find_pid() {
#     local selected_pid
#     selected_pid=$(ps axww -o pid,user,%cpu,%mem,start,time,command | peco --prompt 'PROCESS>' | sed 's/^ *//' | cut -f1 -d' ') || return
#     eval 'LBUFFER="$LBUFFER$selected_pid"'
# }
# zle -N peco_find_pid
# bindkey '^P' peco_find_pid

# peco_find_history() {
#     local selected_entry
#     selected_entry=$(fc -l -n -r 1 | peco --prompt 'HISTORY>')
#     eval 'LBUFFER="$LBUFFER$selected_entry"'
# }
# zle -N peco_find_history
# bindkey '^R' peco_find_history

peco_find_git_uncommitted() {
    local selected_entry
    selected_entry=$(git status --porcelain=v2 --renames | awk '{print $NF}' | peco --layout bottom-up --prompt 'GIT>' | awk '{print $1}')
    eval 'LBUFFER="$LBUFFER$selected_entry"'
}
zle -N peco_find_git_uncommitted
bindkey '^U' peco_find_git_uncommitted
