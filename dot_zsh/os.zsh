# =============================================================================
# OS Detection Helpers
# =============================================================================
# Source this file early in .zshrc before any OS-specific configuration.
# Uses $OSTYPE (zsh built-in) - no subprocess needed.

is_macos() { [[ "$OSTYPE" == darwin* ]]; }
is_linux() { [[ "$OSTYPE" == linux* ]]; }
is_arm()   { [[ "$(uname -m)" == arm64 ]] || [[ "$(uname -m)" == aarch64 ]]; }
is_intel() { [[ "$(uname -m)" == x86_64 ]]; }

# =============================================================================
# Homebrew Prefix Detection
# =============================================================================
# Sets HOMEBREW_PREFIX based on OS and architecture.
# - macOS ARM (M1/M2): /opt/homebrew
# - macOS Intel: /usr/local
# - Linux (Linuxbrew): ~/.linuxbrew or /home/linuxbrew/.linuxbrew

if is_macos; then
  if is_arm; then
    export HOMEBREW_PREFIX="/opt/homebrew"
  else
    export HOMEBREW_PREFIX="/usr/local"
  fi
elif is_linux; then
  if [[ -d "$HOME/.linuxbrew" ]]; then
    export HOMEBREW_PREFIX="$HOME/.linuxbrew"
  elif [[ -d "/home/linuxbrew/.linuxbrew" ]]; then
    export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
  fi
fi
