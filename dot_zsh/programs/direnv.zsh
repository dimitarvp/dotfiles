# Sourced after mise.zsh on purpose: once mise is activated, `direnv` resolves to
# ~/.local/share/mise/installs/direnv/latest/direnv instead of the shim (the shim
# would run mise at every prompt).
#
# direnv bakes the path of its own binary into the hook it prints. On Linux that
# is the versioned install dir, which `mise prune` deletes at the next upgrade:
# every shell started before the upgrade then errors at each prompt, and new
# shells inherit the stale cached hook until the binary behind the cache key
# changes. DIRENV_EXE_PATH (direnv >= 2.38.1) makes it bake the lookup path
# instead: mise repoints `latest` on every upgrade, so the hook keeps working in
# running shells, and the new binary's fresh mtime regenerates the cache.
DIRENV_EXE_PATH=${commands[direnv]} _cache_eval direnv direnv hook zsh
