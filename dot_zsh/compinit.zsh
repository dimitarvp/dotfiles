# Completion setup — replaces Oh-My-Zsh framework.

# Vendored completions (mix).
fpath+=$HOME/.zsh/vendor/completions

# Cargo/rustup completions (regenerates when rustup updates).
local _rustup="$HOME/.cargo/bin/rustup"
if [[ -x "$_rustup" ]]; then
  local _fn_dir="${ZDOTDIR:-$HOME}/.zsh_functions"
  mkdir -p "$_fn_dir"
  if [[ ! -f "$_fn_dir/_cargo" || "$_rustup" -nt "$_fn_dir/_cargo" ]]; then
    "$_rustup" completions zsh cargo > "$_fn_dir/_cargo" 2>/dev/null
    "$_rustup" completions zsh > "$_fn_dir/_rustup" 2>/dev/null
  fi
fi

# -C skips security audit (~25ms faster). Dump file in cache directory.
autoload -Uz compinit && compinit -C -d "$HOME/.cache/zsh/.zcompdump-${HOST}"

# Colored man pages (was: oh-my-zsh colored-man-pages plugin).
export LESS_TERMCAP_mb=$'\e[1;31m'     # begin blink
export LESS_TERMCAP_md=$'\e[1;36m'     # begin bold
export LESS_TERMCAP_me=$'\e[0m'        # reset
export LESS_TERMCAP_so=$'\e[01;33m'    # begin standout (status bar)
export LESS_TERMCAP_se=$'\e[0m'        # end standout
export LESS_TERMCAP_us=$'\e[1;32m'     # begin underline
export LESS_TERMCAP_ue=$'\e[0m'        # end underline
