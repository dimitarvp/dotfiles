# Ruby via Homebrew
if is_macos && [[ -d "$HOMEBREW_PREFIX/opt/ruby/bin" ]]; then
  export PATH="$HOMEBREW_PREFIX/opt/ruby/bin:$PATH"
fi
