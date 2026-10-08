# Use well-known location for `sccache` storage.
export SCCACHE_DIR=$HOME/.cache/sccache

# Utilize `sccache` when compiling Rust.
# $commands is a zsh builtin hash table — instant PATH lookup, no subprocess.
[[ -n "${commands[sccache]}" ]] && export RUSTC_WRAPPER="${commands[sccache]}"
