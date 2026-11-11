#!/usr/bin/env bash
# context_guard.sh — Stop hook. Raises the context alarm at the checkpoint line, before
# Claude Code forces a compaction: a pair-mode session checkpoints, a fully autonomous
# one writes its hydration files and continues through the compaction (both readings
# are in the message below).
#
# Claude Code hands a Stop hook the session id and transcript path but no token
# counts, so occupancy comes from ccctx reading the transcript. The two limits are
# ccctx's defaults, token counts below whatever window the running model actually
# has (published by statusline.sh): the forced compaction, and the checkpoint line
# under it. The hook passes no limits of its own.
#
# Checks only at turn boundaries, so a single turn that starts below the checkpoint
# line can still run into the forced compaction. That is accepted: the alternative is
# no check.
#
# Output contract, from Claude Code's own hook schema:
#   {"decision":"block","reason":"..."} — reason goes to Claude, which then acts
#   {"systemMessage":"..."}             — warning shown, turn still ends
set -uo pipefail

CCCTX="${CTX_GUARD_CCCTX:-$HOME/go/bin/ccctx}"

input=$(cat)
jq_get() { printf '%s' "$input" | jq -r "$1 // empty" 2>/dev/null; }

# Claude Code sets stop_hook_active while a Stop hook is already steering the turn.
# Blocking again there is what turns this into an infinite loop.
[ "$(jq_get '.stop_hook_active')" = "true" ] && exit 0

transcript=$(jq_get '.transcript_path')
session=$(jq_get '.session_id')

emit() {
	printf '%s\n' "$1"
	exit 0
}
note() { # loud, non-blocking: the guard is not working and should be fixed
	emit "$(jq -n --arg m "context guard inactive: $1" '{systemMessage: $m}')"
}

[ -x "$CCCTX" ] || note "ccctx not executable at ${CCCTX}. Install it: go install github.com/dimitarvp/ccctx@latest"

# The report (stdout) stays apart from ccctx's warnings and errors (stderr): a warning
# printed before the report would break the JSON parse.
errfile=$(mktemp "${TMPDIR:-/tmp}/context_guard.XXXXXX") || note "cannot create a temporary file for ccctx's stderr"
trap 'rm -f "$errfile"' EXIT

if [ -n "$transcript" ]; then
	report=$("$CCCTX" -transcript "$transcript" 2>"$errfile")
elif [ -n "$session" ]; then
	report=$("$CCCTX" "$session" 2>"$errfile")
else
	note "the Stop hook payload carried neither .transcript_path nor .session_id, so there is no session to measure"
fi
status=$?
# The details reach jq as one command-line argument, and the OS caps an argument's size.
details=$(head -c 2000 "$errfile")

case $status in
0 | 10) ;; # under, or at or over, the checkpoint line
2) note "ccctx reports FORMAT DRIFT, so context size is unknown and the session can still hit auto-compaction. Details: ${details}" ;;
*) note "ccctx failed (exit ${status}), so context size is unknown and the session can still hit auto-compaction. Details: ${details}" ;;
esac

# Only the first document of the report counts: a broken ccctx that printed many must
# not flood the message below.
field() { printf '%s' "$report" | jq -rn "first(inputs) | $1" 2>/dev/null; }

# Both answers need a report that knows the checkpoint line; one without it comes from
# a ccctx older than this hook, whose exit code means something else, or a broken one.
line=$(field '.checkpoint_line_tokens | numbers')
[ -n "$line" ] || note "the ccctx at ${CCCTX} gave a report without a numeric checkpoint_line_tokens: it is older than this hook, or broken. Update it: go install github.com/dimitarvp/ccctx@latest"

[ "$status" = 0 ] && exit 0

used=$(field '(.high_water_tokens | numbers) // "?"')
compaction=$(field '(.usable_tokens | numbers) // "?"')
left=$(field '(.left_to_compaction_tokens | numbers) // "?"')

reason="Context is at ${used} tokens and the checkpoint line is ${line}. Claude Code forces a compaction at ${compaction}: ${left} tokens are left, and a checkpoint can cost 25,000 to 30,000.

Two readings of this alarm (Dimi, 2026-11-07):
- Pair mode (Dimi is in the loop): invoke the checkpoint skill now — write the
  boarding document, land any pending memory and ledger work, print the restart
  prompt, then tell Dimi the session is ready for /clear.
- Fully autonomous mode (Dimi declared the session autonomous): no pause. Write
  the hydration files (the boarding document, the live step briefs), let the
  auto-compaction land, re-read them through the compact hook and continue.

If you are mid-task, finish only what would be lost otherwise, then act as above —
auto-compaction is close, and it summarizes lossily instead of curating."

jq -n --arg r "$reason" '{decision: "block", reason: $r}'
