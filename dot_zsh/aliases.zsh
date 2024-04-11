# if [ "$(command -v eza)" ]; then
#     unalias -m 'll'
#     unalias -m 'l'
#     unalias -m 'la'
#     unalias -m 'ls'
#     alias ls='eza -G --color auto --icons -a -s type'
#     alias ll='eza -l --color always --icons -a -s type -g --git --time-style full-iso'
# fi

alias exrebuild='fd -HI -t d "deps|_build" -x rm -rf && mix deps.clean --unlock --unused && mix deps.get && mix compile'
alias exclean='fd -HI -t d "deps|_build" -x rm -rf'

alias g='git'
# alias ghfpush='git stash && git hf push && git stash pop'
# alias ghfpull='git stash && git hf pull && git stash pop'
# alias ghfupdate='git stash && git hf update && git stash pop'
alias gtree='git ls-tree -r --name-only HEAD'
alias gchanged="git status --porcelain | awk '{print \$2}'" # This shows modified and untracked entries
alias lsgit='git ls-files'
alias lsgitall='git ls-files --cached --others --exclude-standard'
alias lsrg="rg --files --no-ignore --hidden --follow --glob '!.git/*'"
alias fdgit='fd --no-ignore --hidden --exclude .git --type file --type symlink'
alias fdpid="ps axww -o pid,user,%cpu,%mem,start,time,command | fzf | sed 's/^ *//' | cut -f1 -d' '"
alias ll='eza -l --color always --icons -a -s type -g --git --time-style "+%Y-%b-%d %H:%M:%S%.3f"'
alias llt="ll -T --git-ignore -I '.git|.elixir_ls|.lexical'"
# alias ll='lsd -lgA --group-directories-first --date "+%Y-%b-%d %H:%M:%S%.3f"'
# alias llt="ll --tree -I '.git' -I '.elixir_ls' -I '_build' -I 'cover' -I 'deps' -I 'doc' -I 'target'"
alias listeners1='netstat -an -ptcp | grep LISTEN'
alias listeners2='lsof -i -P | grep -i "listen"'
alias skack='sk --ansi -i -c "ack --color {}"'
alias skag='sk --ansi -i -c "ag --color {}"'
alias skgrep='sk --ansi -i -c "grep -rI --color=always --line-number {} ."'
alias skrg='sk --ansi -i -c "rg --color=always --line-number --ignore-case {}"'
alias skp='sk --ansi -i -c "rg --color=always --line-number --ignore-case {}" --preview "preview.sh {}"'
alias ldd='otool -L'
alias mpvm='mpv --no-audio --loop-playlist=inf'
alias scim='sc-im'
alias min='sort -g | head -n1'
alias max='sort -g -r | head -n1'

alias chrome="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome"
alias ytdl="yt-dlp --config-location $HOME/.config/youtube-dl/config"

alias bri='ddcctl -d 1 -b'

# macOS-specific aliases.
if [ "$system_type" = "Darwin" ]; then
  alias vim='/usr/local/bin/vim'
  alias python='/usr/local/bin/python3.9'
  alias pip='/usr/local/bin/pip3.9'
  alias ls="/usr/local/opt/coreutils/libexec/gnubin/ls"
  alias termgraph='python3 /usr/local/lib/python3.8/site-packages/termgraph/termgraph.py --width 150'
fi

# --------------------------------------------------
# BEGIN: PostgreSQL helpers.
export PG_SHOW_BIGGEST_TABLES="SELECT table_name, pg_total_relation_size(quote_ident(table_name)) FROM information_schema.tables WHERE table_schema = 'public' ORDER BY 2 desc;"
export PG_SHOW_DB_SIZE="SELECT pg_database_size(current_database());"
export PG_SHOW_DB_SIZE_PRETTY="SELECT pg_size_pretty(pg_database_size(current_database()));"

function _pg_table_sizes() {
    psql -AqtF"," -U postgres $1 -c $PG_SHOW_BIGGEST_TABLES;
}

function _pg_db_size() {
    psql -AqtF"," -U postgres $1 -c $PG_SHOW_DB_SIZE;
}

function _pg_db_size_pretty() {
    psql -AqtF"," -U postgres $1 -c $PG_SHOW_DB_SIZE_PRETTY;
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
  curl $CURL_GITHUB_HEADERS $*
}

# ugrep: Aliases to consider:
# alias uq     = 'ug -Q'
# alias ux     = 'ug -UX'
# alias uz     = 'ug -z'
# alias grep   = 'ugrep -G'
# alias egrep  = 'ugrep -E'
# alias fgrep  = 'ugrep -F'
# alias pgrep  = 'ugrep -P'
# alias xgrep  = 'ugrep -UX'
# alias zgrep  = 'ugrep -zG'
# alias zegrep = 'ugrep -zE'
# alias zfgrep = 'ugrep -zF'
# alias zpgrep = 'ugrep -zP'
# alias zxgrep = 'ugrep -zUX'
# alias xdump  = 'ugrep -X ""'

alias tsmicro="ts '[%Y-%m-%d %H:%M:%.S]'"
