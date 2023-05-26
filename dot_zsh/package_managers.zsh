system_type=$(uname -s)

# Programs installed through misc. package managers (only LunarVim, it seems) 
export PATH=$HOME/.local/bin:$PATH 

if [ "$system_type" = "Darwin" ]; then
  # Homebrew: installed programs.
  export PATH=/usr/local/sbin:$PATH

  # Homebrew: `curl`
  export PATH="/usr/local/opt/curl/bin:$PATH"

  # Homebrew: `mysql-client`
  export PATH="/usr/local/opt/mysql-client/bin:$PATH"

  # Homebrew: `sqlite`
  export PATH="/usr/local/opt/sqlite/bin:$PATH"

  # Homebrew: OpenSSL
  export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"
fi
