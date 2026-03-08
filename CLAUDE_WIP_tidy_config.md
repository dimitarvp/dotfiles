# Dotfiles - TODO Tracker

## Key Reference

- **Machines:** robeast (macOS, iMac Pro, Xeon W-2150B 10c/20t @ 3.00GHz), s1 (Linux headless), robotko (Linux desktop, Manjaro)
- **Secrets:** rage + SSH key (`~/.ssh/dotfiles`), `chezmoi init` required after template changes
- **Sync:** `chezmoi git -- reset --hard origin/main && chezmoi git -- pull && chezmoi init && chezmoi apply --force`

---

## TODO

| # | Item | File(s) | Notes |
|---|------|---------|-------|
| ~~N1~~ | ~~Better history lookup (atuin)~~ | — | done: atuin 18.12.1, all 3 machines, host-filtered fuzzy search |
| ~~N2~~ | ~~Linux benchmarks~~ | — | done: robotko 31ms cmd lag, 138ms first prompt (2x faster than macOS) |
| ~~N4~~ | ~~Remove ~/.oh-my-zsh dependency~~ | — | done: plugins + completions vendored, OMZ deleted on all 3 machines |
| N5 | Manage ~/scripts via chezmoi | `~/scripts/*` | mostly done; secrets blocker below |
| ~~N6~~ | ~~Manage exclusion files via chezmoi~~ | — | done: backup + dev as source of truth, rustic auto-generated via template |
| N7 | Try yazi file manager | — | Rust, rich previews (images/PDFs in WezTerm/Kitty/Ghostty, NOT Alacritty). `cargo binstall yazi-fm yazi-cli` |
| N8 | Try gh-dash extension | — | `gh extension install dlvhdr/gh-dash`. TUI dashboard for PRs/issues across repos. One-off install, not a dotfile. |
| N9 | SSH key migration: RSA → Ed25519 | `~/.ssh/*`, SSH configs | 4 keys: master (all machines, full mesh), github, gitlab, srht. GPG signing key Dyad UID already revoked. Classic keys remain as LAN fallback after planned Headscale overlay. Detailed plan in memory/n9_ssh_migration.md |
| R15 | Migrate Python to `uv` | `python.zsh`, `aliases.zsh:41,43` | deferred; plan below |
| R21 | Research fastest CLI backup tool | — | low-prio; borg/rustic/restic compression is bottleneck |

### N1: History lookup — atuin

**Goal:** better relevance, exit code storage, delete entries, fast (Rust).

**Winner: atuin** (Rust, 28k+ stars, actively maintained, monthly releases).

Install: `cargo binstall atuin`. Init: `eval "$(atuin init zsh)"` (cacheable
via `_cache_eval`). SQLite backend at `~/.local/share/atuin/history.db`.

#### Why atuin over alternatives

| Tool | Lang | Stars | Last release | Exit code | Duration | CWD | Delete | Sync | Status |
|------|------|-------|--------------|-----------|----------|-----|--------|------|--------|
| **atuin** | Rust | 28k+ | Feb 2026 | yes | ns precision | yes | TUI + CLI | E2E encrypted | active |
| mcfly | Rust | 7.6k | Dec 2025 | yes | no | yes | F2 key | no | active (community) |
| hstr | C | — | Feb 2026 | no | no | no | yes | no | active |
| zsh-histdb | zsh | 1.4k | — | yes | yes | yes | CLI pattern | git-based | low since 2021 |
| resh | Go | 1k | May 2023 | yes | unconfirmed | yes | no | no | dormant |

**hstr rejected because:**
- Reads flat `~/.zsh_history` — no per-command metadata (exit code, duration, cwd)
- Used TIOCSTI ioctl for prompt injection; Linux 6.2+ disabled this (security fix);
  hstr 3.0+ added zle fallback but transition was messy through 3.1
- Cannot do "show failed commands in this directory" — fundamentally limited by
  the history file format

**mcfly is the only serious alternative** — active, Rust, has TUI deletion. But no
sync, no duration tracking, neural ranking is opaque. atuin does everything mcfly
does and more.

#### Entry deletion

Two methods:
1. **TUI:** Ctrl-R → highlight entry → `Ctrl-O` (inspector) → `Ctrl-D` (delete)
2. **CLI:** `atuin search --delete '^sensitive_command'` (regex, preview without
   `--delete` first)

Deletions propagate via sync (soft-delete `deleted_at` column). Shipped in v14.

#### Filter modes

| Mode | Shows |
|------|-------|
| `global` | all machines |
| `host` | current hostname only |
| `session` | current shell session |
| `directory` | current working directory |
| `workspace` | current git repo |

**Cross-OS filtering:** set `filter_mode = "host"` — robeast sees only macOS
commands, robotko sees only Linux commands. No `yay` on macOS, no `brew` on
Linux. Cycle to `global` via Ctrl-R when needed.

```toml
# ~/.config/atuin/config.toml
filter_mode = "host"
filter_mode_shell_up_key_binding = "host"
search_mode = "fuzzy"
```

#### Sync architecture

Client-server over HTTPS. Clients encrypt entries locally (PASETO v4 /
XChaCha20), push encrypted blobs to server. Server stores opaque ciphertext —
operator cannot read history.

- **Default server:** `api.atuin.sh` (free, Atuin company). Cannot read your data.
- **Self-host:** same MIT-licensed binary. `atuin server start` + PostgreSQL 14+
  or SQLite. Very lightweight (runs on 256MB VMs). Reverse proxy for TLS.
- **No sync:** fully optional. `auto_sync = false` or just never register.

**Encryption key:** generated on `atuin register`, stored at
`~/.local/share/atuin/key` (PASERK base64 string). Never sent to server. To add
machines: `atuin login -u USER -p PASS -k KEY`. Store key in rage-encrypted
secrets alongside other chezmoi secrets.

**Cannot reuse SSH key** — atuin uses symmetric encryption (XChaCha20), SSH keys
are asymmetric (ed25519 signing). Different primitives, incompatible. But the
atuin key can be protected via rage + SSH key indirectly (store it in
`encrypted_secrets.zsh.age`).

**sqlite3_rsync is not a replacement** — strictly one-way (origin → replica),
no merge. Useful as backup only. atuin sync merges individual entries from all
machines bidirectionally.

#### Planned deployment

1. Install atuin on robeast, run without sync initially
2. Replace fzf Ctrl-R binding in `fzf.zsh`
3. Configure `filter_mode = "host"`, `search_mode = "fuzzy"`
4. Cache init with `_cache_eval atuin "atuin init zsh"`
5. Later: self-host sync server on s1, enroll robotko

### N2: Linux benchmarks

macOS (robeast) final numbers: command_lag 65ms, startup 290ms.
Need to run same zsh-bench suite on robotko to compare. Linux fork
overhead is ~1-3ms vs macOS ~10-16ms — expect significantly better numbers.

### N4: Remove ~/.oh-my-zsh dependency

OMZ framework is no longer loaded, but `~/.oh-my-zsh/` is still used as a
**plugin store** on macOS. No runtime cost, just an unmanaged directory.

**Current references:**

1. `zsh_plugins.zsh:2` — macOS plugin path: `$HOME/.oh-my-zsh/custom/plugins`
   - fzf-tab, zsh-autosuggestions, zsh-syntax-highlighting sourced from here
   - On Linux these already come from `/usr/share/zsh/plugins/` (pacman)

2. `compinit.zsh:4-6` — completion fpath entries:
   - `$HOME/.oh-my-zsh/plugins/rust` (completion for cargo/rustup)
   - `$HOME/.oh-my-zsh/plugins/mix` (completion for elixir mix)
   - `$HOME/.oh-my-zsh/plugins/httpie` (completion for http/https)

**Migration plan:**

Vendor all three plugins into `dot_zsh/vendor/` (same pattern as zsh-async).
Unify macOS and Linux to use the same vendored paths.

**Step 1: DONE — plugins vendored**
- fzf-tab v1.2.0, zsh-autosuggestions v0.7.1, zsh-syntax-highlighting 0.8.0
- All in `dot_zsh/vendor/`, platform-specific paths removed from `zsh_plugins.zsh`
- Tested interactively on all 3 machines (robeast, robotko, s1)
- Also added `dot_zshenv` with universal PATH (~/.cargo/bin, ~/.go/bin,
  ~/.local/bin, ~/bin, ~/scripts) so non-interactive SSH sessions find tools
- **Cleanup remaining:** `rm -rf ~/.oh-my-zsh` (macOS), uninstall pacman
  packages (Linux) — do after completions are also vendored

**Step 2: PENDING — negative test**
- `mv ~/.oh-my-zsh ~/.oh-my-zsh.bak` — only after step 3 completions are done

**Step 3: Completions (lower priority, separate pass)**
- rust/cargo: already handled by rustup (generates _cargo/_rustup)
- mix: check if elixir/mise ships it, or vendor the file
- httpie: check if pip ships it, or vendor

### N5: Manage ~/scripts via chezmoi

**Goal:** all scripts in `~/scripts/` tracked by chezmoi. Platform-specific
scripts use chezmoi templates with role/tag data.

**Prerequisites:**
- Add `role` and `has_gui` to each machine's `~/.config/chezmoi/chezmoi.toml`:
  - robeast: `role = "workstation"`, `has_gui = true`, `has_brew = true`
  - s1: `role = "server"`, `has_gui = false`, `has_brew = false`
  - robotko: `role = "workstation"`, `has_gui = true`, `has_brew = false`

#### Priority 1 — Blocked on secrets extraction from `dimi_backup_setup`

All of these scripts either contain secrets directly or source `dimi_backup_setup`
(which has Borg/Restic/Rustic/Kopia/Knoxite passwords, rclone remote definitions).
Cannot add to chezmoi until secrets are extracted into `encrypted_secrets.zsh.age`
or similar.

| Script | Relationship |
|--------|-------------|
| `dimi_backup_setup` | **root cause** — contains all backup passwords and rclone remotes |
| `borg_clean_cache.sh` | sources dimi_backup_setup |
| `borg_reset_profile.sh` | sources dimi_backup_setup |
| `borg2kopia.sh` | sources dimi_backup_setup |
| `borg2restic.sh` | sources dimi_backup_setup |
| `borg2rustic.sh` | sources dimi_backup_setup |
| `capture_profile.sh` | sources dimi_backup_setup |
| `kopia_backup` | sources kopia_capture_backups + kopia_upload_backups (both source dimi_backup_setup) |
| `kopia_capture_backups` | sources dimi_backup_setup |
| `kopia_empty_remotes` | sources dimi_backup_setup |
| `kopia_reset` | has password inline |
| `kopia_upload_backups` | sources dimi_backup_setup |
| `rustic_backup.sh` | sources dimi_backup_setup |
| `rustic_reset` | sources dimi_backup_setup |
| `update_all` | has password/token inline |
| `upload_profile.sh` | sources dimi_backup_setup |

#### Deferred (not secrets-related)

| Script | Status |
|--------|--------|
| `tws_ssh_paper.sh` | ignored for now (work SSH tunnels) |
| `tws_ssh_real.sh` | ignored for now (work SSH tunnels) |

#### Deleted

| Script | Why |
|--------|-----|
| `restic_backup.sh` | replaced by rustic |
| `restic_reset` | replaced by rustic |
| `backup_profile.sh` | superseded by capture_profile.sh + upload_profile.sh |
| `backup_media.sh` | deleted by user (hardcoded password, rezerva3 collision) |

#### Done (N5 scripts added to chezmoi across sessions)

All scripts in ~/scripts/ are now either chezmoi-managed or blocked on secrets.
`provision_manjaro.sh` was fully rewritten. `restic_backup.sh` and `restic_reset`
deleted (replaced by rustic). `mlr_*`, `tv_*`, `xsv_*` tabular wrappers deleted
(replaced by csvlens). `preview*.sh` deleted. `merge_two_videos.sh` and
`merge_video_and_subs.sh` deleted (cheatsheets, not scripts).

### R15: Python / uv migration plan (deferred)

**Current pain:** Python 3.12 hardcoded in 3 places, LDFLAGS hacks, alias overrides.

**Why uv over mise for Python:** uv is purpose-built (versions + packages + venvs + dependency resolution).

**Phases:**
1. Replace curl-installed uv with cargo-managed (`cargo binstall uv`)
2. Inventory global pip packages, move CLI tools to `uv tool install`
3. Install Python via uv (`uv python install 3.13`)
4. Update dotfiles: delete `python.zsh`, delete pip aliases, add wrapper
   scripts `~/scripts/pip` and `~/scripts/pip3` (`exec uv pip "$@"`)
5. Optionally uninstall Homebrew Python
6. Test on all 3 machines

---

## DONE

| Item | Description |
|------|-------------|
| Double compinit | Removed from zsh.zsh, Oh-My-Zsh handles it |
| Duplicate z plugin | Removed, using zoxide |
| History size | Reduced from 10M to 1M |
| Bash completion in zsh | Removed, zsh has own |
| Gitconfig indentation | All 2-space (mergetool, delta line-numbers, insteadOf fixed) |
| Dead/commented code | Removed eza block, ghf, lsd, ugrep, cross-compile, emplace.zsh |
| OS detection helpers | Created os.zsh (is_macos, is_linux, HOMEBREW_PREFIX) |
| PATH reorganization | Centralized in package_managers.zsh, uses HOMEBREW_PREFIX |
| Intel Mac paths | All use HOMEBREW_PREFIX |
| declare usage | Simplified in zsh_plugins.zsh |
| Linux paths | Linuxbrew supported via HOMEBREW_PREFIX |
| OpenSSL 1.1 | Moot — not installed |
| autocomplete.zsh | Deleted |
| Cache rustc sysroot | Binary-mtime cache + $commands builtin for sccache |
| Cache eval subprocesses | _cache_eval helper for zoxide, direnv, mise |
| Fix git_changed() | Only unstaged + untracked |
| Remove paths.zsh | Was just comments |
| Secrets management | rage + SSH key, encrypted_secrets.zsh.age, verified 3 machines |
| WezTerm double middle-click | Changed Up to Down event |
| Git cleanup scripts | git-largest, git-largest-orphaned, git-forget, git-cleanup |
| Consolidate fuzzy finders | fzf only; removed peco, skim, fzy, preview scripts |
| Font defaults to 18 | WezTerm and Kitty changed from 22 |
| Re-enable fzf-tab | Fixed by compinit cleanup |
| Fix Esc-c / Alt-C collision | Unbind \ec, rebind directory picker to Ctrl-O |
| Preview pane scrolling | Ctrl-F/Ctrl-B in FZF_DEFAULT_OPTS |
| explore function | Replaced skim skp alias with fzf + rg + bat |
| git-main script | Reliable default branch detection; fixed git h, stat, sync aliases |
| git stat fixed | Was using undefined $REVIEW_BASE, now uses origin/$(git main) |
| curl_github quoting | Changed $* to "$@" |
| Remove bogus LOCALE | Not a valid POSIX variable |
| Ctrl-U widget fix | Guard non-git dirs, zle reset-prompt after fzf |
| R3: Remove bison LDFLAGS | Unused; was overwriting Python's LDFLAGS |
| R4: core.editor = nvim | Was vim, contradicted EDITOR=nvim |
| R5: Cross-platform clipboard | pbcopy on macOS, wl-copy on Linux (Wayland) |
| R9: Peco config kept | Intentionally retained for now |
| R10: Fix misleading comment | Was about fzf tab, actually autosuggest strategy |
| R11: Clean ohmyzsh.zsh | Removed 44 lines of scaffold boilerplate |
| R12: README.md updated | Added kitty_font_size and wezterm_font_size |
| R13: Alacritty scrollback 100K | Max supported by alacritty (was 10M, capped at 100K) |
| R14: Set VISUAL=nvim | Many programs check VISUAL before EDITOR |
| R16: Delete stale mise config | XDG config had pinned versions overriding loose ones in dot_mise.toml |
| R17: Strip .chezmoiignore | Scaffold removed; only ignores README.md and WIP file |
| R19: getconf is fine | <1ms syscall, not worth optimizing |
| R20: Auto-detect PostgreSQL | Glob postgresql@*, sort by version, warn if psql exists but no brew pg |
| F1: Fix HISTORY_IGNORE | Was HISTIGNORE (bash); changed to HISTORY_IGNORE with zsh glob syntax |
| F2: Remove DISABLE_AUTO_UPDATE | Contradicted zstyle ':omz:update' mode auto |
| F3: Normalize gitconfig indent | mergetool, delta line-numbers, insteadOf all 2-space now |
| F4: Remove git_default_branch() | Dead code, replaced by git-main script |
| F5: Delete env.zsh | NVIM_LSP_LOG not a standard neovim var; removed file and source line |
| F6: Strip HIST_STAMPS comments | 6 lines of Oh-My-Zsh scaffold removed |
| N3: Replace zsh prompt | p10k -> starship -> hand-built pure-zsh prompt with async git (3ms) |
| Drop starship | Replaced with dot_zsh/prompt.zsh (~230 lines), deleted starship.toml |
| Delete p10k config | Removed 1770-line dot_p10k.zsh, deleted ~/.p10k.zsh on all machines |
| Vendor zsh-async | dot_zsh/vendor/async.zsh (v1.8.6, MIT, eliminates package dep) |
| RPROMPT elimination | Starship set RPROMPT but $fill made it empty; cleared to save 12ms |
| ZSH_AUTOSUGGEST_MANUAL_REBIND | Stops 33ms per-prompt widget rebinding; one-shot on first prompt |
| Cross-platform fzf-tab | Probe both fzf-tab/ and fzf-tab-git/ (AUR package name differs) |
| Cross-platform compinit | mkdir -p ~/.zsh_functions before writing rustup completions |
| fzf keybindings on Linux | Source from /usr/share/fzf/ instead of unmanaged ~/.fzf.zsh |
| Eliminate ~/.fzf.zsh dep | Source fzf from $HOMEBREW_PREFIX/opt/fzf/shell/ or /usr/share/fzf/ |
| README rewrite | Comprehensive dev reference; audited against repo, fixed 4 false claims |
| Remove youtube-dl | Empty directory removed from chezmoi source and deployed config |
| N2: Linux benchmarks | robotko: 31ms cmd lag, 138ms first prompt; 2x faster than macOS |
| Backup sources audit | Removed 7 stale BACKUP_SOURCES (OMZ, p10k, httpie, influx, mysql, profile, utop) |
| Backup scripts cleanup | Removed bupstash/knoxite/pcloud, fixed kopia_reset KOPIA_REPOSITORY→KOPIA_REPO bug |
| Backup sourcing normalize | All scripts use `. "$(command -v dimi_backup_setup)"` (POSIX portable) |
| kopia_upload multitail | Switched from GNU parallel to multitail (matches upload_profile.sh) |
| lvim exclusion removed | Stale entry from backup.exclusions; rustic copy auto-synced via chezmoi template |
