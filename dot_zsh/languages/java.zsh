# OpenJDK via Homebrew
if is_macos && [[ -d "$HOMEBREW_PREFIX/opt/openjdk/bin" ]]; then
  export PATH="$HOMEBREW_PREFIX/opt/openjdk/bin:$PATH"
fi
