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

# The dump (the command → completion-function table) is rebuilt from scratch
# once a day and used as is (-C) in between. -C alone never rescans fpath, so
# completion files that arrive later stay unregistered until something deletes
# the dump: by 2026-10-09 the March dump had outlived a zsh upgrade and lacked
# ~150 commands (age, zstd, 7z, npm, tldr, the zsh 5.9.2 set). The rebuild
# costs ~0.5 s on the mac, ~0.2 s on the Linux boxes, once a day. -u: should
# compaudit ever flag a group-writable fpath directory, it would prompt and
# block the shell start; use the directories anyway. The glob (N.mh-24)
# matches the dump only when it was modified within the last 24 hours.
autoload -Uz compinit
_dump="$HOME/.cache/zsh/.zcompdump-${HOST}"
_dump_fresh=("$_dump"(N.mh-24))
if (($#_dump_fresh)); then
  compinit -C -d "$_dump"
else
  rm -f -- "$_dump"
  compinit -u -d "$_dump"
fi
unset _dump _dump_fresh

# Colored man pages (was: oh-my-zsh colored-man-pages plugin).
export LESS_TERMCAP_mb=$'\e[1;31m'  # begin blink
export LESS_TERMCAP_md=$'\e[1;36m'  # begin bold
export LESS_TERMCAP_me=$'\e[0m'     # reset
export LESS_TERMCAP_so=$'\e[01;33m' # begin standout (status bar)
export LESS_TERMCAP_se=$'\e[0m'     # end standout
export LESS_TERMCAP_us=$'\e[1;32m'  # begin underline
export LESS_TERMCAP_ue=$'\e[0m'     # end underline
