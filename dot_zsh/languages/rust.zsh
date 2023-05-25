export PATH="$HOME/.cargo/bin:$PATH"

# Accelerate Rust's autocomplete daemon by pointing it at Rust's sources.
export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/library"

# Use well-known location for `sccache` storage.
export SCCACHE_DIR=~/.cache/sccache

# Utilize `sccache` when compiling Rust.
export RUSTC_WRAPPER=`which sccache`

# Taken from https://github.com/messense/homebrew-macos-cross-toolchains
# NOTE: this is disabled because cross-compiling on macOS is not working on all
# platforms that I'd like; hence, such scenarios will be offloaded to containers.
# export CC_x86_64_unknown_linux_gnu=x86_64-unknown-linux-gnu-gcc
# export CXX_x86_64_unknown_linux_gnu=x86_64-unknown-linux-gnu-g++
# export AR_x86_64_unknown_linux_gnu=x86_64-unknown-linux-gnu-ar
# export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=x86_64-unknown-linux-gnu-gcc
