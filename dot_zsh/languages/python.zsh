system_type=$(uname -s)

if [ "$system_type" = "Darwin" ]; then
  export PATH="/usr/local/opt/python@3.8/bin:$PATH"
  export LDFLAGS="-L/usr/local/opt/python@3.8/lib"
  export PKG_CONFIG_PATH="/usr/local/opt/python@3.8/lib/pkgconfig"
fi
