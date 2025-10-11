if [ "$system_type" = "Darwin" ]; then
  export PATH="/usr/local/opt/python@3.12/bin:$PATH"
  export LDFLAGS="-L/usr/local/opt/python@3.12/lib"
  export PKG_CONFIG_PATH="/usr/local/opt/python@3.12/lib/pkgconfig"
fi
