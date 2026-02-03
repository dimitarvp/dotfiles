# Python 3.12 via Homebrew
if is_macos && [[ -d "$HOMEBREW_PREFIX/opt/python@3.12" ]]; then
  export PATH="$HOMEBREW_PREFIX/opt/python@3.12/bin:$PATH"
  export LDFLAGS="-L$HOMEBREW_PREFIX/opt/python@3.12/lib"
  export PKG_CONFIG_PATH="$HOMEBREW_PREFIX/opt/python@3.12/lib/pkgconfig"
fi
