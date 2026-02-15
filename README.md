# Dotfiles

Managed with [chezmoi](https://www.chezmoi.io/). Targets macOS (Intel) and Linux (Manjaro/Arch).

Secrets encrypted with [rage](https://github.com/str4d/rage) via SSH key (`~/.ssh/dotfiles`). Encrypted files: `~/.zsh/secrets.zsh`.

## Shell (zsh)

Modular config split across `~/.zsh/`. Oh-My-Zsh still used as plugin store on macOS (pending removal); plugins sourced from system paths on Linux.

**Prompt:** hand-built powerline with round pill separators, async git via vendored [zsh-async](https://github.com/mafredri/zsh-async). Shows OS icon, full directory, git branch + dirty state (staged/modified/untracked/ahead/behind/stashed), command duration (>3s), background jobs, SSH hostname, and time. Second line: `❯` colored by exit status. Renders in ~3ms. Path: p10k → starship (42ms fork overhead) → this.

**History search:** Ctrl-R via [fzf](https://github.com/junegunn/fzf). Ctrl-T for file picker, Ctrl-O for directory picker, Ctrl-U for git uncommitted files. Preview with [bat](https://github.com/sharkdp/bat). Ctrl-Y copies selected command to clipboard.

**Plugins:** [fzf-tab](https://github.com/Aloxaf/fzf-tab) (tab completion through fzf), [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) (fish-like ghost text), [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) (command coloring).

**Caching:** `_cache_eval` helper caches output of `tool init zsh` commands (zoxide, direnv, mise). Invalidates on binary mtime change. Saves ~100ms startup.

**OS detection:** `is_macos`, `is_linux`, `is_arm`, `is_intel` helpers. `$HOMEBREW_PREFIX` set per-platform.

**GNU on macOS:** coreutils, grep, tar, texinfo override macOS BSD variants via PATH.

## Languages

| Language | Manager | Config |
|----------|---------|--------|
| Erlang | mise | KERL flags, REPL history, memory tuning |
| Elixir | mise | CPU-aware dep compilation (`MIX_OS_DEPS_COMPILE_PARTITION_COUNT`) |
| Rust | rustup/cargo | sccache, native CPU target, mold linker (Linux), LTO release |
| Go | homebrew | `GOPATH`, `~/.go/bin` on PATH |
| Java | homebrew | OpenJDK path |
| Python | homebrew | 3.12 path, linker flags |
| Ruby | homebrew | path |
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

## Terminal emulators

Four configs, all templated for per-machine font size. Font: UbuntuMono Nerd Font. Color scheme: Dracula-inspired.

| Terminal | Config format |
|----------|--------------|
| WezTerm | Lua (primary — Alt/Meta key handling, word navigation, middle-click paste) |
| Kitty | INI |
| Alacritty | TOML |
| Ghostty | custom |

## Git

`dot_gitconfig`: histogram diff, zdiff3 merge conflicts, delta pager, GPG commit signing, SSH URL rewrite for GitHub. Aliases for common operations (`st`, `co`, `br`, `df`, `h` for log, `sync` for pull+push, `stat` for diff against default branch).

`dot_gitignore`: global ignores (.DS_Store, .elixir_ls, .envrc, node_modules, .tool-versions).

[jj](https://github.com/martinvonz/jj) (Jujutsu VCS) also configured: GPG signing, delta pager.

## Scripts

**Git maintenance:**
- `git-main` — detect default branch
- `git-forget` — remove file from entire history (git-filter-repo)
- `git-cleanup` — remove blobs above size threshold
- `git-largest` / `git-largest-orphaned` — find large objects

**Tool convergence:**
- `cargo_converge` / `cargo_export` — sync installed Rust crates to `crates.conf` (80+ tools)
- `gup_converge` / `gup_export` — sync installed Go tools to `gup.conf` (30+ tools)

**Utilities:**
- `fsize_histogram` — file size distribution
- `biggest_first` / `count_files` / `count_dirs` — directory stats
- `sqlite3_tables_and_row_counts` — SQLite table stats
- `claude-sessions` — fuzzy-pick and resume Claude Code sessions

## Cargo crates

`~/.config/cargo-crates/crates.conf` is the source of truth. `cargo_converge` installs missing, updates outdated, and prunes unlisted crates via `cargo binstall`. 80+ tools including ripgrep, fd, bat, eza, hyperfine, tokei, bottom, dust, bandwhich, cargo-audit, cargo-deny, cargo-expand.

## Other configs

| File | Purpose |
|------|---------|
| `dot_mise.toml` | Erlang 27+28, Elixir 1.18+1.19, rebar, converge task |
| `dot_cargo/config.toml` | Sparse registry, native CPU, mold (Linux), LTO release |
| `dot_npmrc` | `ignore-scripts=true` |
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
    wezterm_font_size = 20
```

All default to 18.

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
