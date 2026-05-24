ulimit -n 98304

export EDITOR=nvim
export VISUAL=nvim

# Terminals set this locally but SSH doesn't forward it; pin it so headless
# / remote shells (s1, robogamer) advertise truecolor support to apps too.
: ${COLORTERM:=truecolor}
export COLORTERM

WORDCHARS='*?_[]~=&;!#$%^(){}<>'
