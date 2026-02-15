# Pure-zsh powerline prompt with async git via zsh-async.
# Replaces starship (~42ms/prompt) with in-process rendering (~2-3ms).
#
# Layout:
#   Line 1: [os] [directory] [git_branch] [git_dirty] ───── [duration] [jobs] [host] [time]
#   Line 2: ❯
#
# Requires: zsh-async (vendor/async.zsh), zsh/datetime

zmodload zsh/datetime
zmodload zsh/mathfunc

# ── Glyphs and constants ─────────────────────────────────────────

typeset -g _PL=$'\uE0B4'      # right half circle (pill close)
typeset -g _PR=$'\uE0B6'      # left half circle  (pill open)
typeset -g _GIT_ICON=$'\uF126' # git branch icon
typeset -g _FILL_CHAR=$'\u2500' # ─ horizontal line for fill gap
typeset -g _ARROW_UP=$'\u21E1'  # ⇡ ahead
typeset -g _ARROW_DN=$'\u21E3'  # ⇣ behind
typeset -g _PROMPT_CH=$'\u276F' # ❯ prompt character
typeset -g _JOBS_STAR=$'\u2726' # ✦ jobs indicator

if [[ "$OSTYPE" == darwin* ]]; then
  typeset -g _OS_ICON=$'\uF179'   # macOS
else
  typeset -g _OS_ICON=$'\uF17C'   # Linux
fi

# ── Async git worker ─────────────────────────────────────────────

# Runs in background worker. Single git call for everything.
_prompt_git_query() {
  cd -q "$1" 2>/dev/null || return 1
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || return 1

  local staged=0 modified=0 untracked=0 ahead=0 behind=0 stashed=0
  local line
  while IFS= read -r line; do
    case "$line" in
      '# branch.ab '*)
        ahead=${${line#*+}%% *}
        behind=${line##*-}
        ;;
      '1 '??' '*|'2 '??' '*)
        [[ ${line:2:1} != '.' ]] && (( staged++ ))
        [[ ${line:3:1} != '.' ]] && (( modified++ ))
        ;;
      '? '*)
        (( untracked++ ))
        ;;
    esac
  done < <(git status --porcelain=v2 --branch 2>/dev/null)

  stashed=$(git stash list 2>/dev/null | wc -l)

  print "${branch}|${staged}|${modified}|${untracked}|${ahead}|${behind}|${stashed## }"
}

_prompt_git_callback() {
  local job=$1 code=$2 output=$3

  if [[ $job == '_prompt_git_query' ]]; then
    if (( code == 0 )) && [[ -n $output ]]; then
      local parts=(${(s:|:)output})
      typeset -g _pg_branch=${parts[1]}
      typeset -g _pg_staged=${parts[2]}
      typeset -g _pg_modified=${parts[3]}
      typeset -g _pg_untracked=${parts[4]}
      typeset -g _pg_ahead=${parts[5]}
      typeset -g _pg_behind=${parts[6]}
      typeset -g _pg_stashed=${parts[7]}
    else
      typeset -g _pg_branch=""
    fi
    _prompt_render
    zle && zle reset-prompt
  fi
}

# ── Prompt rendering ─────────────────────────────────────────────

_prompt_render() {
  local left="" right=""
  local left_len=0 right_len=0

  # Expand directory now so we can measure width
  local cwd=${(%):-%~}

  # ── Left side: connected pills ──────────────────────

  # OS icon (white bg, black fg)
  left+="%F{white}${_PR}%f%K{white}%F{black} ${_OS_ICON} %f"
  left+="%F{white}%K{blue}${_PL}%f"
  (( left_len += 5 ))  # open + space + icon + space + transition

  # Directory (blue bg, white fg)
  left+="%F{white} ${cwd} %f"
  (( left_len += ${#cwd} + 2 ))

  # Git branch (green bg, black fg)
  if [[ -n $_pg_branch ]]; then
    left+="%F{blue}%K{green}${_PL}%f%F{black} ${_GIT_ICON} ${_pg_branch} %f"
    (( left_len += 1 + 2 + ${#_pg_branch} + 2 ))
    left+="%k%F{green}${_PL}%f"
    (( left_len += 1 ))

    # Git dirty (yellow pill, standalone, conditional)
    local dirty="" dirty_len=0
    (( _pg_staged > 0 ))    && dirty+="+${_pg_staged} "    && (( dirty_len += 2 + ${#_pg_staged} ))
    (( _pg_modified > 0 ))  && dirty+="!${_pg_modified} "  && (( dirty_len += 2 + ${#_pg_modified} ))
    (( _pg_untracked > 0 )) && dirty+="?${_pg_untracked} " && (( dirty_len += 2 + ${#_pg_untracked} ))
    (( _pg_ahead > 0 ))     && dirty+="${_ARROW_UP}${_pg_ahead} "  && (( dirty_len += 2 + ${#_pg_ahead} ))
    (( _pg_behind > 0 ))    && dirty+="${_ARROW_DN}${_pg_behind} " && (( dirty_len += 2 + ${#_pg_behind} ))
    (( _pg_stashed > 0 ))   && dirty+="*${_pg_stashed} "   && (( dirty_len += 2 + ${#_pg_stashed} ))

    if [[ -n $dirty ]]; then
      left+="%F{yellow}${_PR}%f%K{yellow}%F{black}${dirty}%f%k%F{yellow}${_PL}%f"
      (( left_len += 2 + dirty_len ))
    fi
  else
    # No git: close blue pill
    left+="%k%F{blue}${_PL}%f"
    (( left_len += 1 ))
  fi

  # ── Right side: standalone pills ────────────────────

  # Command duration (>3s, yellow pill)
  if [[ -n $_prompt_duration ]]; then
    local dur=" ${_prompt_duration} "
    right+="%F{yellow}${_PR}%f%K{yellow}%F{black}${dur}%f%k%F{yellow}${_PL}%f"
    (( right_len += 2 + ${#dur} ))
  fi

  # Background jobs (black pill, cyan text)
  local njobs=${(%):-%j}
  if (( njobs > 0 )); then
    local jt=" ${_JOBS_STAR} ${njobs} "
    right+="%F{black}${_PR}%f%K{black}%F{cyan}${jt}%f%k%F{black}${_PL}%f"
    (( right_len += 2 + ${#jt} ))
  fi

  # SSH hostname (gray pill)
  if [[ -n $SSH_CONNECTION ]]; then
    local ht=" ${HOST} "
    right+="%F{240}${_PR}%f%K{240}%F{white}${ht}%f%k%F{240}${_PL}%f"
    (( right_len += 2 + ${#ht} ))
  fi

  # Time (white pill, always)
  local tn
  strftime -s tn '%H:%M:%S' $EPOCHSECONDS
  local tt=" ${tn} "
  right+="%F{white}${_PR}%f%K{white}%F{black}${tt}%f%k%F{white}${_PL}%f"
  (( right_len += 2 + ${#tt} ))

  # ── Fill gap ────────────────────────────────────────
  local gap=$(( COLUMNS - left_len - right_len ))
  (( gap < 1 )) && gap=1
  local fc=$_FILL_CHAR
  local fill="%F{240}${(pl:${gap}::$fc:)}%f"

  # ── Prompt character ────────────────────────────────
  local char
  if (( _prompt_exit_code == 0 )); then
    char="%F{#5fd700}${_PROMPT_CH}%f"
  else
    char="%F{red}${_PROMPT_CH}%f"
  fi

  PROMPT="${left}${fill}${right}"$'\n'"${char} "
  RPROMPT=""
}

# ── Hooks ─────────────────────────────────────────────────────────

_prompt_preexec() {
  typeset -g _prompt_cmd_start=$EPOCHREALTIME
}

_prompt_precmd() {
  typeset -g _prompt_exit_code=$?

  # Command duration (only show if >=3s)
  typeset -g _prompt_duration=""
  if (( ${+_prompt_cmd_start} )); then
    local elapsed=$(( EPOCHREALTIME - _prompt_cmd_start ))
    if (( elapsed >= 3.0 )); then
      if (( elapsed >= 3600 )); then
        _prompt_duration="$(( int(elapsed / 3600) ))h$(( int(elapsed % 3600 / 60) ))m"
      elif (( elapsed >= 60 )); then
        _prompt_duration="$(( int(elapsed / 60) ))m$(( int(elapsed % 60) ))s"
      else
        _prompt_duration="$(( int(elapsed) ))s"
      fi
    fi
    unset _prompt_cmd_start
  fi

  # Kick off async git query
  async_flush_jobs _prompt_worker
  async_job _prompt_worker _prompt_git_query "$PWD"

  # Render immediately with cached git state
  _prompt_render
}

# ── Init ──────────────────────────────────────────────────────────

_prompt_setup() {
  typeset -g _pg_branch="" _pg_staged=0 _pg_modified=0 _pg_untracked=0
  typeset -g _pg_ahead=0 _pg_behind=0 _pg_stashed=0
  typeset -g _prompt_duration="" _prompt_exit_code=0

  setopt promptsubst

  async_init
  async_start_worker _prompt_worker -n
  async_register_callback _prompt_worker _prompt_git_callback

  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _prompt_precmd
  add-zsh-hook preexec _prompt_preexec

  _prompt_render
}

_prompt_setup
