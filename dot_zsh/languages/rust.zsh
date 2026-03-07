# Accelerate Rust's autocomplete daemon by pointing it at Rust's sources.
# Caches the sysroot path — auto-regenerates when rustc binary updates.
_rustc_cache="$HOME/.cache/zsh/rustc_sysroot"
if [[ -n "${commands[rustc]}" ]] && [[ ! -f "$_rustc_cache" || "${commands[rustc]}" -nt "$_rustc_cache" ]]; then
    mkdir -p "${_rustc_cache:h}"
    rustc --print sysroot > "$_rustc_cache"
fi
[[ -f "$_rustc_cache" ]] && export RUST_SRC_PATH="$(<$_rustc_cache)/lib/rustlib/src/rust/library"

# Use well-known location for `sccache` storage.
export SCCACHE_DIR=$HOME/.cache/sccache

# Utilize `sccache` when compiling Rust.
# $commands is a zsh builtin hash table — instant PATH lookup, no subprocess.
[[ -n "${commands[sccache]}" ]] && export RUSTC_WRAPPER="${commands[sccache]}"
