system_type=$(uname -s)

if [ "$system_type" = "Darwin" ]; then
  export ASDF_DIR=$(brew --prefix asdf)/libexec
  . $(brew --prefix asdf)/libexec/asdf.sh
  . $(brew --prefix asdf)/etc/bash_completion.d/asdf.bash
elif [ "$system_type" = "Linux" ]; then
  . /opt/asdf-vm/asdf.sh
else
  echo "UNKNOWN SYSTEM: $(uname -a)"
fi

