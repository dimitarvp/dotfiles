# `mise activate zsh` embeds the caller's PATH verbatim in its output, so it must
# be evaluated live: a cached copy freezes whatever PATH the regenerating shell
# had — an ssh session's PATH on WSL lacks the Windows directories, so a cache
# made there took explorer.exe off every new wt tab's PATH and xdg-open stopped
# reaching the Windows browser (2026-09-03). Costs a few ms per shell.
eval "$(mise activate zsh)"
_cache_eval mise_direnv mise direnv
