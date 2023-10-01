system_type=$(uname -s)

if [ "$system_type" = "Darwin" ]; then
  export LIBRARY_PATH='/usr/local/opt/gcc@12/lib/gcc/12:/usr/local/opt/libgccjit/lib/gcc/current:/usr/local/opt/gcc@12/lib/gcc/12/gcc/x86_64-apple-darwin21/12'
fi
