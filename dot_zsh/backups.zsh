system_type=$(uname -s)

if [ "$system_type" = "Darwin" ]; then
  source $HOME/scripts/dimi_backup_setup
fi
