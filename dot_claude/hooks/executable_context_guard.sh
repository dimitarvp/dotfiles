#!/usr/bin/env bash
# context_guard.sh — Stop hook. Asks Claude to checkpoint before the context window
# fills, so the session ends on a curated boarding instead of a lossy auto-compaction.
#
# Claude Code hands a Stop hook the session id and transcript path but no token
# counts, so occupancy comes from ccctx reading the transcript. The threshold is a
# fraction of whatever window the running model actually has (published by
# statusline.sh), never a hardcoded ceiling.
#
# Checks only at turn boundaries, so a single turn that starts well below the
# threshold can still overshoot it. That is accepted: the alternative is no check.
#
# Output contract, from Claude Code's own hook schema:
#   {"decision":"block","reason":"..."} — reason goes to Claude, which then acts
#   {"systemMessage":"..."}             — warning shown, turn still ends
set -uo pipefail

FRACTION="${CTX_GUARD_FRACTION:-0.96}"
CCCTX="${CTX_GUARD_CCCTX:-$HOME/go/bin/ccctx}"

input=$(cat)
jq_get() { printf '%s' "$input" | jq -r "$1 // empty" 2>/dev/null; }

# Claude Code sets stop_hook_active while a Stop hook is already steering the turn.
# Blocking again there is what turns this into an infinite loop.
[ "$(jq_get '.stop_hook_active')" = "true" ] && exit 0

transcript=$(jq_get '.transcript_path')
session=$(jq_get '.session_id')

emit() { printf '%s\n' "$1"; exit 0; }
note() { # loud, non-blocking: the guard is not working and should be fixed
	emit "$(jq -n --arg m "context guard inactive: $1" '{systemMessage: $m}')"
}

[ -x "$CCCTX" ] || note "ccctx not executable at ${CCCTX}. Build it: cd ~/kod/ccctx && go build -o \$HOME/go/bin/ccctx ."

if [ -n "$transcript" ]; then
	report=$("$CCCTX" -threshold "$FRACTION" -transcript "$transcript" 2>&1)
elif [ -n "$session" ]; then
	report=$("$CCCTX" -threshold "$FRACTION" "$session" 2>&1)
else
	note "the Stop hook payload carried neither .transcript_path nor .session_id, so there is no session to measure"
fi
status=$?

case $status in
0) exit 0 ;; # under threshold
10) ;;       # over — fall through and ask for a checkpoint
2) note "ccctx reports FORMAT DRIFT, so context size is unknown and the session can still hit auto-compaction. Details: ${report}" ;;
*) note "ccctx failed (exit ${status}), so context size is unknown and the session can still hit auto-compaction. Details: ${report}" ;;
esac

used=$(printf '%s' "$report" | jq -r '.high_water_tokens // "?"' 2>/dev/null)
window=$(printf '%s' "$report" | jq -r '.window_tokens // "?"' 2>/dev/null)
pct=$(printf '%s' "$report" | jq -r 'if .used_pct then (.used_pct | round | tostring) else "?" end' 2>/dev/null)

reason="Context is at ${used} of ${window} tokens (${pct}%), past the ${FRACTION} guard.

Invoke the checkpoint skill now: write the boarding document, land any pending
memory and ledger work, and print the restart prompt. Then tell Dimi the session
is ready for /clear.

If you are mid-task, finish only what would be lost otherwise, then checkpoint —
auto-compaction is close, and it summarizes lossily instead of curating."

jq -n --arg r "$reason" '{decision: "block", reason: $r}'
