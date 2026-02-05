# Cache the output of slow shell-init commands (eval "$(tool init zsh)").
# Regenerates automatically when the tool's binary is updated.
#
# Usage: _cache_eval <cache-name> <command> [args...]
# Example: _cache_eval zoxide zoxide init zsh
_cache_eval() {
    local cache_name=$1; shift
    local cache="$HOME/.cache/zsh/${cache_name}.zsh"
    local bin=${commands[$1]}

    if [[ -n "$bin" ]] && [[ ! -f "$cache" || "$bin" -nt "$cache" ]]; then
        mkdir -p "${cache:h}"
        "$@" > "$cache"
    fi
    [[ -f "$cache" ]] && source "$cache"
}
