# Programs installed through misc. package managers (only LunarVim, it seems)
export PATH=$HOME/.local/bin:$PATH

if [ "$system_type" = "Darwin" ]; then
  # Homebrew: installed programs.
  export PATH=/usr/local/sbin:$PATH
  export PATH=/opt/homebrew/bin:$PATH

  # Homebrew: `curl`
  export PATH="/usr/local/opt/curl/bin:$PATH"

  # Homebrew: `mysql-client`
  export PATH="/usr/local/opt/mysql-client/bin:$PATH"

  # Homebrew: `sqlite`
  export PATH="/usr/local/opt/sqlite/bin:$PATH"

  # Homebrew: `postgresql`
  export PATH="/usr/local/opt/postgresql@18/bin:$PATH"

  # Homebrew: OpenSSL
  export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"
fi
