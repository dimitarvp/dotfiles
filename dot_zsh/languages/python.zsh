if [ "$system_type" = "Darwin" ]; then
  export PATH="/usr/local/opt/python@3.9/bin:$PATH"
  export LDFLAGS="-L/usr/local/opt/python@3.9/lib"
  export PKG_CONFIG_PATH="/usr/local/opt/python@3.9/lib/pkgconfig"
fi
