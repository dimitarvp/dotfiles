# Dotfiles

Managed with [chezmoi](https://www.chezmoi.io/). Targets macOS and Linux; templates branch on the OS, and one maintenance script (`pacman_orphan_sweep`) is for Arch-based distributions.

Private files are encrypted with [age](https://age-encryption.org/) through [rage](https://github.com/str4d/rage), using an SSH key (`~/.ssh/dotfiles`). Encrypted source files carry the `encrypted_` prefix and the `.age` suffix.

## Shell (zsh)

Modular config split across `~/.zsh/`. No plugin framework: the plugins are vendored under `~/.zsh/vendor/` and sourced directly on every OS.

**Prompt:** hand-built powerline with round pill separators, async git via vendored [zsh-async](https://github.com/mafredri/zsh-async). Shows OS icon, full directory, git branch + dirty state (staged/modified/untracked/ahead/behind/stashed), command duration (>3s), background jobs, SSH hostname, and time. Second line: `❯` colored by exit status. Renders in ~3ms.

**History search:** Ctrl-R and Up arrow via [atuin](https://github.com/atuinsh/atuin) (fuzzy search, compact style, preview).

**Fuzzy pickers:** [fzf](https://github.com/junegunn/fzf) with [fd](https://github.com/sharkdp/fd) as the file source. Ctrl-T for file picker, Ctrl-O for directory picker, Ctrl-U for git uncommitted files. Preview with [bat](https://github.com/sharkdp/bat).

**Plugins:** [fzf-tab](https://github.com/Aloxaf/fzf-tab) (tab completion through fzf), [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) (fish-like ghost text), [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) (command coloring).

**Caching:** `_cache_eval` helper caches output of `tool init zsh` commands (zoxide, direnv, atuin). Invalidates on binary mtime change. Saves ~100ms startup.

**OS detection:** `is_macos`, `is_linux`, `is_arm`, `is_intel` helpers. `$HOMEBREW_PREFIX` set per-platform.

**GNU on macOS:** coreutils, grep, tar, texinfo (from Homebrew or MacPorts) override macOS BSD variants via PATH.

## Languages

| Language | Manager | Config |
|----------|---------|--------|
| Erlang | mise | KERL flags, REPL history, memory tuning |
| Elixir | mise | CPU-aware dep compilation (`MIX_OS_DEPS_COMPILE_PARTITION_COUNT`) |
| Rust | rustup/cargo | sccache, native CPU target, mold linker (Linux), LTO release |
| Go | mise | `GOBIN` set to `~/go/bin` |
| Python | mise (macOS), uv | Python CLI tools in uv-managed venvs through mise's pipx backend |
| OCaml | opam | opam init |

## Programs

| Program | What it does |
|---------|-------------|
| [mise](https://mise.jdx.dev/) | Polyglot version manager (Erlang, Elixir, rebar, node, etc.) |
| [direnv](https://direnv.net/) | Per-directory environment via `.envrc` |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smart `cd` with frecency |
| [delta](https://github.com/dandavison/delta) | Git pager with syntax highlighting (DarkNeon theme, side-by-side) |
| [pspg](https://github.com/okbob/pspg) | PostgreSQL pager |
| Docker | BuildKit enabled |

## Terminal emulators and multiplexer

Kitty, Alacritty and Ghostty configs, all templated for per-machine font size. Font: UbuntuMono Nerd Font. Color scheme: Dracula-inspired.

| Program | Config format |
|----------|--------------|
| Kitty | INI |
| Alacritty | TOML |
| Ghostty | custom |
| [zellij](https://zellij.dev/) | KDL: starts locked, detaches on close, Alt+PageUp/PageDown scroll the pane; `zl`, `zr`, `zs`, `zd`, `zk` shell helpers attach, list, delete and kill sessions, locally or over ssh |

## Git

`dot_gitconfig`: histogram diff, zdiff3 merge conflicts, delta pager, GPG commit signing, SSH URL rewrite for GitHub. Aliases for common operations (`st`, `co`, `br`, `df`, `h` for log, `sync` for pull+push, `stat` for diff against default branch).

`dot_gitignore`: global ignores (.DS_Store, editor and language-server folders, .envrc, node_modules, .tool-versions).

[jj](https://github.com/martinvonz/jj) (Jujutsu VCS) also configured: GPG signing, delta pager.

## Scripts

**Git maintenance:**
- `git-main`: detect default branch
- `git-forget`: remove file from entire history (git-filter-repo)
- `git-cleanup`: remove blobs above size threshold
- `git-largest` / `git-largest-orphaned`: find large objects
- `git-churn`: rank files by lines added and removed

**Tool convergence:**
- `cargo_converge` / `cargo_export`: sync installed Rust crates to `crates.conf` (90+ tools)
- `gup_converge` / `gup_export`: sync installed Go tools to `gup.json` (40+ tools)

**Utilities:**
- `fsize_histogram`: file size distribution
- `biggest_first` / `count_files` / `count_dirs`: directory stats
- `sqlite3_tables_and_row_counts`: SQLite table stats
- `claude-sessions`: fuzzy-pick and resume Claude Code sessions

## Cargo crates

`~/.config/cargo-crates/crates.conf` is the source of truth. `cargo_converge` installs missing, updates outdated, and prunes unlisted crates via `cargo binstall`. 90+ tools including ripgrep, fd, bat, eza, hyperfine, tokei, bottom, dust, bandwhich, cargo-audit, cargo-deny, cargo-expand.

## Other configs

| File | Purpose |
|------|---------|
| `private_dot_config/mise/config.toml.tmpl` | Every mise-managed tool, one owner per tool, the converge task |
| `dot_cargo/config.toml` | Sparse registry, native CPU, mold (Linux), LTO release |
| `dot_npmrc` | npm: install scripts off, 7-day release age; `dot_zshenv` exports the same lock for npm and pnpm, so a repository's own config cannot undo it |
| `private_dot_config/pnpm/config.yaml` | pnpm: install scripts off, 7-day release age; macOS reaches it through the symlink under `Library/Preferences/pnpm` |
| `scripts/executable_build_dep` | The one sanctioned way to run a dependency's install scripts: inspect, type yes, build one package inside a cage (sandbox-exec on macOS, bwrap on Linux), one log line per run; `build_dep_test` is its acceptance test, escape attempts included |
| `private_dot_config/pueue/pueue.yml` | pueue daemon and client settings; `PUEUE_CONFIG_PATH` in `dot_zshenv` points every OS at it; the apply step enables the login daemon (systemd user unit on Linux, launchd agent on macOS) and creates the groups heavy (1) and light (3); the callback writes the run ledger |
| `scripts/executable_pueue_ledger_record` | Run ledger: pueue's callback writes one JSON record per finished task (verdict, exit code, 50-line log tail) to `~/.local/state/pueue_ledger/records.jsonl` |
| `private_dot_config/atuin/config.toml` | Fuzzy history search, compact style, preview |
| `dot_psqlrc` | Pager off |
| `dot_vimrc` | Minimal (ruler, syntax, indent) |
| `yt-dlp/config` | AV1 preference, SponsorBlock, subtitles, metadata |
| `rust-analyzer/settings.json` | clippy as check command |
| `peco/config.json` | Keybindings and styling |
| `mpv/mpv.conf` | Audio normalization, default volume, screen target |
| `sc-im/scimrc` | Color scheme (headings, grid, selection) |
| `mise/settings.toml` | Legacy version files, asdf compat, auto-install |
| `dot_visidatarc` | Disable motd |

## Machine-local overrides

Create `~/.config/chezmoi/chezmoi.toml`:

```toml
[data]
    alacritty_font_size = 22.5
    ghostty_font_size = 22
    ghostty_adjust_cell_height = 1
    kitty_font_size = 20
```

Font sizes default to 18; `ghostty_adjust_cell_height` defaults to 0.

## Setup

```sh
chezmoi init dimitarvp/dotfiles
chezmoi apply
```

Encrypted files require the SSH key at `~/.ssh/dotfiles`. After template changes: `chezmoi init && chezmoi apply`.

Sync across machines:
```sh
chezmoi git -- reset --hard origin/main && chezmoi git -- pull && chezmoi init && chezmoi apply --force
```
