if [ "$system_type" = "Darwin" ]; then
  if [ -f "$HOME/scripts/dimi_backup_setup" ]; then
    source $HOME/scripts/dimi_backup_setup
  fi
fi
