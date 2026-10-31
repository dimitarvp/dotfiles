# =============================================================================
# Package Managers & PATH Configuration
# =============================================================================
# Requires: os.zsh must be sourced first (provides HOMEBREW_PREFIX, is_macos, etc.)
#
# PATH priority (highest to lowest); the last block of this file enforces 3-4:
#   1. mise-managed tools (mise activate prepends its install dirs later)
#   2. GNU replacements for BSD tools (macOS only, gnu.zsh)
#   3. User's personal binaries (~/.local/bin, ~/.cargo/bin, ~/go/bin, ~/bin, ~/scripts)
#   4. MacPorts (macOS), then Homebrew
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

  # curl (prefer Homebrew's newer version)
  [[ -d "$HOMEBREW_PREFIX/opt/curl/bin" ]] && \
    export PATH="$HOMEBREW_PREFIX/opt/curl/bin:$PATH"
fi

# -----------------------------------------------------------------------------
# MacPorts (macOS): binary-only ports, ahead of Homebrew while both exist
# -----------------------------------------------------------------------------
if is_macos && [[ -d /opt/local/bin ]]; then
  export PATH="/opt/local/bin:/opt/local/sbin:$PATH"
  export MANPATH="/opt/local/share/man:${MANPATH}"
  # psql, pg_ctl and friends of the newest installed postgresqlNN port
  local -a _mp_pg
  _mp_pg=(/opt/local/lib/postgresql<->/bin(N/On))
  (( $#_mp_pg )) && export PATH="${_mp_pg[1]}:$PATH"
fi

# -----------------------------------------------------------------------------
# User lanes win over every package manager (priority 3 above): move them back
# to the front after the prepends above. typeset -U (zshenv) keeps one entry
# per directory, so this reorders PATH instead of duplicating it.
# -----------------------------------------------------------------------------
path=($HOME/.local/bin $HOME/.cargo/bin $HOME/go/bin $HOME/bin $HOME/scripts $path)
