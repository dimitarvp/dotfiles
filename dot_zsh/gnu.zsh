if [ "$system_type" = "Darwin" ]; then
  export PATH=/usr/local/opt/bison/bin:$PATH # GNU bison
  export PATH=/usr/local/opt/texinfo/bin:$PATH # GNU texinfo
  export PATH=/usr/local/opt/gnu-tar/libexec/gnubin:$PATH # GNU tar

  export LDFLAGS="-L/usr/local/opt/bison/lib"

  # To use all GNU core utilities, uncomment these:
  export PATH="/usr/local/opt/coreutils/libexec/gnubin:${PATH}"
  export MANPATH="/usr/local/opt/coreutils/libexec/gnuman:${MANPATH}"

  # GNU grep.
  export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"
fi

