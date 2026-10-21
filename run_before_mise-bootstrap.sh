#!/bin/sh
# Bootstrap mise's own binary from the vendor release when it is missing; `mise run converge` updates it afterwards.
set -eu
bin="$HOME/.local/bin/mise"
[ -x "$bin" ] && exit 0
curl -fsSL https://mise.run | MISE_INSTALL_PATH="$bin" sh
