# =============================================================================
# GNU Tools (macOS)
# =============================================================================
# Replace BSD utilities with GNU versions on macOS.
# Requires: os.zsh must be sourced first.

if is_macos && [[ -n "$HOMEBREW_PREFIX" ]]; then
  # GNU coreutils (ls, cat, cp, mv, etc.)
  if [[ -d "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin" ]]; then
    export PATH="$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH"
    export MANPATH="$HOMEBREW_PREFIX/opt/coreutils/libexec/gnuman:${MANPATH}"
  fi

  # GNU grep
  [[ -d "$HOMEBREW_PREFIX/opt/grep/libexec/gnubin" ]] && \
    export PATH="$HOMEBREW_PREFIX/opt/grep/libexec/gnubin:$PATH"

  # GNU tar
  [[ -d "$HOMEBREW_PREFIX/opt/gnu-tar/libexec/gnubin" ]] && \
    export PATH="$HOMEBREW_PREFIX/opt/gnu-tar/libexec/gnubin:$PATH"

  # GNU texinfo
  [[ -d "$HOMEBREW_PREFIX/opt/texinfo/bin" ]] && \
    export PATH="$HOMEBREW_PREFIX/opt/texinfo/bin:$PATH"
fi
