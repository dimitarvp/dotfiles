# Completion setup — replaces Oh-My-Zsh framework.

# Vendored completions (mix).
fpath+=$HOME/.zsh/vendor/completions

# Cargo/rustup completions (regenerates when rustup updates).
local _rustup="$HOME/.cargo/bin/rustup"
if [[ -x "$_rustup" ]]; then
  local _fn_dir="${ZDOTDIR:-$HOME}/.zsh_functions"
  mkdir -p "$_fn_dir"
  if [[ ! -f "$_fn_dir/_cargo" || "$_rustup" -nt "$_fn_dir/_cargo" ]]; then
    "$_rustup" completions zsh cargo >"$_fn_dir/_cargo" 2>/dev/null
    "$_rustup" completions zsh >"$_fn_dir/_rustup" 2>/dev/null
  fi
fi

# -C uses the dump (the command → completion-function table) as is, no fpath
# rescan and no compaudit (~25 ms saved per shell), and builds it only when the
# file is missing. New tools bring new completion files, so the update scripts
# (update_all, update_via_gotask) delete the dump at the end of every run; the
# next shell rebuilds it once (~0.5 s). A tool installed by hand outside those
# scripts gets its completion after `rm ~/.cache/zsh/.zcompdump-*`.
autoload -Uz compinit && compinit -C -d "$HOME/.cache/zsh/.zcompdump-${HOST}"

# Colored man pages (was: oh-my-zsh colored-man-pages plugin).
export LESS_TERMCAP_mb=$'\e[1;31m'  # begin blink
export LESS_TERMCAP_md=$'\e[1;36m'  # begin bold
export LESS_TERMCAP_me=$'\e[0m'     # reset
export LESS_TERMCAP_so=$'\e[01;33m' # begin standout (status bar)
export LESS_TERMCAP_se=$'\e[0m'     # end standout
export LESS_TERMCAP_us=$'\e[1;32m'  # begin underline
export LESS_TERMCAP_ue=$'\e[0m'     # end underline
