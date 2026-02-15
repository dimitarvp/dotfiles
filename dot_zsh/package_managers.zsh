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
  local _pg_dir
  _pg_dir=$(ls -d "$HOMEBREW_PREFIX"/opt/postgresql@*/bin 2>/dev/null | sort -t@ -k2 -rn | head -1)
  if [[ -n "$_pg_dir" ]]; then
    export PATH="$_pg_dir:$PATH"
  elif command -v psql &>/dev/null; then
    echo "⚠️  Homebrew PostgreSQL not found but psql is in PATH — check package_managers.zsh" >&2
  fi

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
