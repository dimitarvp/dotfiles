# Erlang installed through `asdf`: always build docs.
export KERL_BUILD_DOCS=yes
export KERL_INSTALL_MANPAGES=yes
export KERL_INSTALL_HTMLDOCS=yes

# Enable Erlang/Elixir REPL history
export ERL_AFLAGS="-kernel shell_history enabled"
