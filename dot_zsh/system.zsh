ulimit -n 98304

# nvim where it is installed, vim elsewhere (a server carries no editor stack).
if command -v nvim >/dev/null 2>&1; then
	export EDITOR=nvim
else
	export EDITOR=vim
fi
export VISUAL=$EDITOR
# sudoedit and visudo look the editor up by bare name in sudo's fixed PATH (the
# system folders only), where a home-folder nvim is never found: without this
# line they fall back to vi. vim is in /usr/bin on every machine.
export SUDO_EDITOR=vim

# Terminals set this locally but SSH doesn't forward it; pin it so headless
# / remote shells advertise truecolor support to apps too.
: ${COLORTERM:=truecolor}
export COLORTERM

WORDCHARS='*?_[]~=&;!#$%^(){}<>'
