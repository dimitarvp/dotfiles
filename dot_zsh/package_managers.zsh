# =============================================================================
# Package Managers & PATH Configuration
# =============================================================================
# Requires: os.zsh must be sourced first (provides HOMEBREW_PREFIX, is_macos, etc.)
#
# PATH priority (highest to lowest):
#   1. User's personal binaries (~/.local/bin, ~/bin, ~/scripts)
#   2. Language-specific (cargo, go) - added by their respective files
#   3. Homebrew-installed tools (formula bins)
#   4. GNU replacements for BSD tools (macOS only)
#   5. System paths

# -----------------------------------------------------------------------------
# Homebrew base paths
# -----------------------------------------------------------------------------
if [[ -n "$HOMEBREW_PREFIX" ]]; then
  export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:$PATH"
fi

# -----------------------------------------------------------------------------
# Homebrew formula-specific paths (macOS)
# -----------------------------------------------------------------------------
if is_macos && [[ -n "$HOMEBREW_PREFIX" ]]; then
  # Database clients
  [[ -d "$HOMEBREW_PREFIX/opt/mysql-client/bin" ]] && \
    export PATH="$HOMEBREW_PREFIX/opt/mysql-client/bin:$PATH"
  [[ -d "$HOMEBREW_PREFIX/opt/sqlite/bin" ]] && \
    export PATH="$HOMEBREW_PREFIX/opt/sqlite/bin:$PATH"
  [[ -d "$HOMEBREW_PREFIX/opt/postgresql@18/bin" ]] && \
    export PATH="$HOMEBREW_PREFIX/opt/postgresql@18/bin:$PATH"

  # curl (prefer Homebrew's newer version)
  [[ -d "$HOMEBREW_PREFIX/opt/curl/bin" ]] && \
    export PATH="$HOMEBREW_PREFIX/opt/curl/bin:$PATH"
fi

# -----------------------------------------------------------------------------
# User's personal binaries (highest priority - added last)
# -----------------------------------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/scripts:$PATH"
