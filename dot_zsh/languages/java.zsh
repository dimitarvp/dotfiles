system_type=$(uname -s)

if [ "$system_type" = "Darwin" ]; then
  export PATH=/usr/local/opt/openjdk/bin:$PATH # OpenJDK
fi

