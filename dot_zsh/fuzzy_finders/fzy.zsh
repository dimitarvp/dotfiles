# ALT-C: cd into the selected directory
# CTRL-T: Place the selected file path in the command line
# CTRL-R: Place the selected command from history in the command line
# CTRL-P: Place the selected process ID in the command line
# bindkey '\ec' fzy-cd-widget
# bindkey '^T'  fzy-file-widget
# bindkey '^R'  fzy-history-widget
# bindkey '^P'  fzy-proc-widget

# zstyle :fzy:tmux    enabled      no

# zstyle :fzy:history show-scores  no
# zstyle :fzy:history lines        '25'
# zstyle :fzy:history prompt       ' '
# zstyle :fzy:history command      fzy-history-default-command

# zstyle :fzy:file    show-scores  no
# zstyle :fzy:file    lines        '25'
# zstyle :fzy:file    prompt       '> '
# #zstyle :fzy:file    command      fzy-file-default-command
# zstyle :fzy:file    command      fd -t f

# zstyle :fzy:cd      show-scores  no
# zstyle :fzy:cd      lines        '25'
# zstyle :fzy:cd      prompt       'cd >> '
# #zstyle :fzy:cd      command      fzy-cd-default-command
# zstyle :fzy:cd      command      fd -t d

# zstyle :fzy:proc    show-scores  no
# zstyle :fzy:proc    lines        '25'
# zstyle :fzy:proc    prompt       'proc >> '
# zstyle :fzy:proc    command      fzy-proc-default-command
