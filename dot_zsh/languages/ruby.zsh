system_type=$(uname -s)

if [ "$system_type" = "Darwin" ]; then
  export PATH=/usr/local/opt/ruby/bin:$PATH
fi
