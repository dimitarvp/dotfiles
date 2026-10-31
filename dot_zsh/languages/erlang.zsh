# Always build docs.
export KERL_BUILD_DOCS=yes
export KERL_INSTALL_MANPAGES=yes
export KERL_INSTALL_HTMLDOCS=yes

# We don't care about ODBC. On the Mac the crypto app links MacPorts' OpenSSL 3
# (Homebrew's libraries are leaving); Linux builds find the distro's OpenSSL.
if is_macos && [[ -d /opt/local/libexec/openssl3 ]]; then
  export KERL_CONFIGURE_OPTIONS='--without-odbc --with-ssl=/opt/local'
else
  export KERL_CONFIGURE_OPTIONS='--without-odbc'
fi

# Enable Erlang/Elixir REPL history
export ERL_AFLAGS="-kernel shell_history enabled"

# Reduces memory usage.
# https://elixirforum.com/t/elixir-erlang-docker-containers-ram-usage-on-different-oss-kernels/57251/16
export ERL_MAX_PORTS=1024
