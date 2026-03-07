alias exrebuild='fd -HI -t d "deps|_build" -x rm -rf && mix deps.clean --unlock --unused && mix deps.get && mix compile'
alias exclean='fd -HI -t d "deps|_build" -x rm -rf'

alias g='git'
alias gtree='git ls-tree -r --name-only HEAD'
alias gchanged="git status --porcelain | awk '{print \$2}'" # This shows modified and untracked entries
alias lsgit='git ls-files'
alias lsgitall='git ls-files --cached --others --exclude-standard'
alias lsrg="rg --files --no-ignore --hidden --follow --glob '!.git/*'"
alias fdgit='fd --no-ignore --hidden --exclude .git --type file --type symlink'
alias fdpid="ps axww -o pid,user,%cpu,%mem,start,time,command | fzf | sed 's/^ *//' | cut -f1 -d' '"
alias ll='eza -l --color always --icons -a -s type -g --git --time-style "+%Y-%b-%d %H:%M:%S%.3f"'
alias llt="ll -T --git-ignore -I '.git|.elixir_ls|.lexical'"
alias llmax='ll -r -s size --total-size'
alias listeners1='netstat -an -ptcp | grep LISTEN'
alias listeners2='lsof -i -P | grep -i "listen"'
explore() {
    fzf --ansi --disabled \
        --bind "start:reload:rg --color=always --line-number --ignore-case {q} || true" \
        --bind "change:reload:rg --color=always --line-number --ignore-case {q} || true" \
        --delimiter : \
        --preview 'bat --color=always --style=numbers --highlight-line {2} {1}' \
        --preview-window '+{2}-/2' \
        --query "${1:-}"
}
alias mpvm='mpv --no-audio --loop-playlist=inf'
alias scim='sc-im'
alias min='sort -g | head -n1'
alias max='sort -g -r | head -n1'
alias biggest_first='sort -rn -k 5'
alias rmf='rm -rf'
alias rmv='rm -rfv'

# macOS-specific aliases
if is_macos; then
  alias ldd='otool -L'
  alias chrome="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome"
  alias bri='ddcctl -d 1 -b'  # monitor brightness via ddcctl

  # Prefer Homebrew versions
  [[ -x "$HOMEBREW_PREFIX/bin/vim" ]] && alias vim="$HOMEBREW_PREFIX/bin/vim"
  [[ -x "$HOMEBREW_PREFIX/bin/python3.12" ]] && alias python="$HOMEBREW_PREFIX/bin/python3.12"
  [[ -x "$HOMEBREW_PREFIX/bin/python3.12" ]] && alias python3="$HOMEBREW_PREFIX/bin/python3.12"
  [[ -x "$HOMEBREW_PREFIX/bin/pip3.12" ]] && alias pip="$HOMEBREW_PREFIX/bin/pip3.12"
  # Note: ls uses GNU coreutils via PATH (see gnu.zsh)
fi

alias ytdl="yt-dlp"

# --------------------------------------------------
# BEGIN: PostgreSQL helpers.
export PG_SHOW_BIGGEST_TABLES="SELECT table_name, pg_total_relation_size(quote_ident(table_name)) FROM information_schema.tables WHERE table_schema = 'public' ORDER BY 2 desc;"
export PG_SHOW_DB_SIZE="SELECT pg_database_size(current_database());"
export PG_SHOW_DB_SIZE_PRETTY="SELECT pg_size_pretty(pg_database_size(current_database()));"

function _pg_table_sizes() {
  psql -AqtF"," -U postgres $1 -c $PG_SHOW_BIGGEST_TABLES
}

function _pg_db_size() {
  psql -AqtF"," -U postgres $1 -c $PG_SHOW_DB_SIZE
}

function _pg_db_size_pretty() {
  psql -AqtF"," -U postgres $1 -c $PG_SHOW_DB_SIZE_PRETTY
}

alias pg_table_sizes='_pg_table_sizes'
alias pg_db_size='_pg_db_size'
alias pg_db_size_pretty='_pg_db_size_pretty'
# END: PostgreSQL helpers.
# --------------------------------------------------

function _mix_hex_latest_1() {
  mix hex.info $1 | grep 'Config:' | sed 's/.*{\(.*\)}[^}]*/{\1},/'
}
alias mix_hex_latest1='_mix_hex_latest_1'

function _mix_hex_latest_2() {
  curl --silent https://hex.pm/api/packages/$1 | jq -r '.configs."mix.exs"'
}
alias mix_hex_latest2='_mix_hex_latest_2'

# Utilities.
alias histocsv="jp -input csv -xy '[*][0,1]' -type bar -height 53"

# Misc.

function curl_github() {
  curl $CURL_GITHUB_HEADERS "$@"
}

alias tsmicro="ts '[%Y-%m-%d %H:%M:%.S]'"
