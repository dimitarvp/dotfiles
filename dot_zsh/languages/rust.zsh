export PATH="$HOME/.cargo/bin:$PATH"

# Accelerate Rust's autocomplete daemon by pointing it at Rust's sources.
export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/library"

# Use well-known location for `sccache` storage.
export SCCACHE_DIR=$HOME/.cache/sccache

# Utilize `sccache` when compiling Rust.
export RUSTC_WRAPPER=`which sccache`
