# Always build docs.
export KERL_BUILD_DOCS=yes
export KERL_INSTALL_MANPAGES=yes
export KERL_INSTALL_HTMLDOCS=yes

# We don't care about ODBC.
export KERL_CONFIGURE_OPTIONS='--without-odbc'

# Enable Erlang/Elixir REPL history
export ERL_AFLAGS="-kernel shell_history enabled"
