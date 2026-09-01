#!/usr/bin/env bash
# statusline.sh — Claude Code status line.
# Reads session JSON on stdin, prints:
#   cwd • model • effort • ctx • 5h limit • 7d all-other • 7d fable
# rate_limits is absent until the session's first API response; parts degrade away.
# The Fable weekly bucket is NOT in the statusline payload (still true at CC
# 2.1.252) — it is fetched from Anthropic's undocumented OAuth usage endpoint
# (same source as /usage), cached in ~/.cache; stale or unfetchable data
# degrades to omission, never to another account's numbers.

input=$(cat)

{
	IFS= read -r dir
	IFS= read -r model_id
	IFS= read -r effort
	IFS= read -r p5
	IFS= read -r r5
	IFS= read -r p7
	IFS= read -r r7
	IFS= read -r ctx_used
	IFS= read -r ctx_size
	IFS= read -r ctx_pct
	IFS= read -r session_id
} < <(jq -r '
	.workspace.current_dir // .cwd // "?",
	.model.id // "?",
	(.effort.level // ""),
	(.rate_limits.five_hour.used_percentage  | if type == "number" then round | tostring else "" end),
	(.rate_limits.five_hour.resets_at        | if type == "number" then floor | tostring else "" end),
	(.rate_limits.seven_day.used_percentage  | if type == "number" then round | tostring else "" end),
	(.rate_limits.seven_day.resets_at        | if type == "number" then floor | tostring else "" end),
	((.context_window.total_input_tokens // 0) + (.context_window.total_output_tokens // 0) | tostring),
	(.context_window.context_window_size     | if type == "number" then tostring else "" end),
	(.context_window.used_percentage         | if type == "number" then round | tostring else "" end),
	(.session_id // "")
' <<<"$input")

# GNU vs BSD date/stat. On the mac, brew coreutils' gnubin dir shadows both
# names in PATH with GNU-flavored ones whose -r/-f mean something else — so
# darwin binds the system binaries by absolute path. Bare `date +%s`-style
# calls are flavor-agnostic and stay bare.
if [ "$(uname)" = Darwin ]; then
	IS_DARWIN=1
	epoch_fmt() { /bin/date -r "$1" "+$2"; }
	stat_mtime() { /usr/bin/stat -f %m "$1" 2>/dev/null || echo 0; }
else
	IS_DARWIN=0
	epoch_fmt() { date -d "@$1" "+$2"; }
	stat_mtime() { stat -c %Y "$1" 2>/dev/null || echo 0; }
fi

# Fable weekly limit via the OAuth usage endpoint, cached. The token lives in
# the macOS Keychain on darwin (CC moves it there on login and deletes
# ~/.claude/.credentials.json) and in ~/.claude/.credentials.json on linux.
# Darwin must read the Keychain FIRST: a leftover credentials file there can
# belong to a previously-logged-in account and must not win. Token is read
# fresh per fetch (CC rotates it) and passed via curl --config stdin, never
# argv.
# Retry throttling and data freshness are tracked separately: the .attempt
# sidecar limits fetches to one per 120s, while the cache file's mtime is only
# ever set by a successful fetch — so the display refuses data older than
# 300s instead of serving numbers from a dead login (how a stuck "7d 100%"
# survived an account switch on 2026-09-01).
USAGE_CACHE="$HOME/.cache/claude_usage_limits.json"

get_token() {
	local t=""
	if [ "$IS_DARWIN" = 1 ]; then
		t=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null |
			jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
	fi
	[ -n "$t" ] || t=$(jq -r '.claudeAiOauth.accessToken // empty' "$HOME/.claude/.credentials.json" 2>/dev/null)
	printf '%s' "$t"
}

file_age() { # seconds since mtime of $1; missing file reads as very old
	printf '%s' $(( $(date +%s) - $(stat_mtime "$1") ))
}

fetch_usage() {
	local tok tmpf
	[ "$(file_age "$USAGE_CACHE.attempt")" -lt 120 ] && return 0
	mkdir -p "$HOME/.cache" && touch "$USAGE_CACHE.attempt"
	tok=$(get_token)
	[ -n "$tok" ] || return 0
	tmpf=$(mktemp "${TMPDIR:-/tmp}/clusage.XXXXXX") || return 0
	if curl -sf --max-time 2 -o "$tmpf" --config /dev/stdin <<EOF
url = "https://api.anthropic.com/api/oauth/usage"
header = "Authorization: Bearer $tok"
header = "anthropic-beta: oauth-2025-04-20"
EOF
	then
		mv "$tmpf" "$USAGE_CACHE" && chmod 600 "$USAGE_CACHE"
	else
		rm -f "$tmpf"
	fi
}

fetch_usage
pf="" rf=""
if [ -f "$USAGE_CACHE" ] && [ "$(file_age "$USAGE_CACHE")" -le 300 ]; then
	pf=$(jq -r '[.limits[]? | select(.kind == "weekly_scoped")][0] | .percent | round | tostring' "$USAGE_CACHE" 2>/dev/null) || pf=""
	[ "$pf" = "null" ] && pf=""
	# resets_at is ISO with fractional secs (…59:59.9…): strip fraction, +1 lands
	# on the true boundary; jq fromdate keeps this portable (no GNU/BSD date).
	rf=$(jq -r '[.limits[]? | select(.kind == "weekly_scoped")][0] | .resets_at | sub("\\.[0-9]+"; "") | sub("\\+00:00"; "Z") | fromdate + 1 | tostring' "$USAGE_CACHE" 2>/dev/null) || rf=""
	[ "$rf" = "null" ] && rf=""
fi

fmt_date_hm() { # "7 Jul 14:00"
	local out
	out=$(epoch_fmt "$1" '%d %b %H:%M')
	printf '%s' "${out#0}"
}

fmt_day_hm() { # "Today 17:00" / "Tomorrow 09:30", else "7 Jul 14:00"
	local ts=$1 day hm
	day=$(epoch_fmt "$ts" %Y-%m-%d)
	hm=$(epoch_fmt "$ts" %H:%M)
	if [ "$day" = "$(date +%Y-%m-%d)" ]; then
		printf 'Today %s' "$hm"
	elif [ "$day" = "$(epoch_fmt $(( $(date +%s) + 86400 )) %Y-%m-%d)" ]; then
		printf 'Tomorrow %s' "$hm"
	else
		fmt_date_hm "$ts"
	fi
}

case $dir in "$HOME"*) dir="~${dir#"$HOME"}" ;; esac
model="${model_id#claude-}"

ESC=$'\033'
RST="${ESC}[0m"
DIM="${ESC}[2m"
GRN="${ESC}[38;5;70m"
YEL="${ESC}[38;5;220m"
ORN="${ESC}[38;5;208m"
PUR="${ESC}[38;5;135m"
RED="${ESC}[1;38;5;196m"

# model chip: white on family color
case $model in
	fable-5*) model_c="${ESC}[1;38;5;231;48;5;28m" ;;  # grass green
	*opus*)   model_c="${ESC}[1;38;5;231;48;5;166m" ;; # orange
	*)        model_c="${ESC}[1;38;5;231;48;5;31m" ;;  # cyan
esac

# effort heat ramp: low → max
case $effort in
	max)    effort_c=$RED ;;
	xhigh)  effort_c=$ORN ;;
	high)   effort_c=$YEL ;;
	medium) effort_c="${ESC}[38;5;76m" ;;
	low)    effort_c="${ESC}[38;5;75m" ;;
	*)      effort_c="" ;;
esac

pct_c() { # threshold color for $1 (integer %)
	if [ "$1" -ge 80 ]; then printf '%s' "$RED"
	elif [ "$1" -ge 50 ]; then printf '%s' "$YEL"
	else printf '%s' "$GRN"; fi
}

ctx_c() { # context pressure: <50 green, <70 yellow, <85 orange, ≥85 red
	if [ "$1" -ge 85 ]; then printf '%s' "$RED"
	elif [ "$1" -ge 70 ]; then printf '%s' "$ORN"
	elif [ "$1" -ge 50 ]; then printf '%s' "$YEL"
	else printf '%s' "$GRN"; fi
}

hm_tok() { # humanize token count: 330472 → 330k, 1000000 → 1.0m
	if [ "$1" -ge 1000000 ]; then
		local d=$(( ($1 * 10 + 500000) / 1000000 ))
		printf '%d.%dm' $(( d / 10 )) $(( d % 10 ))
	else
		printf '%dk' $(( ($1 + 500) / 1000 ))
	fi
}

parts=("${DIM}${dir}${RST}" "${model_c} ${model} ${RST}")
[ -n "$effort" ] && parts+=("${effort_c}${effort}${RST}")
if [ -n "$ctx_pct" ] && [ -n "$ctx_size" ]; then
	parts+=("$(hm_tok "$ctx_used") / $(hm_tok "$ctx_size") $(ctx_c "$ctx_pct")(${ctx_pct}%)${RST}")
fi
if [ -n "$p5" ]; then
	seg="$(pct_c "$p5")5h ${p5}%${RST}"
	[ -n "$r5" ] && seg="$seg ${DIM}↻ $(fmt_day_hm "$r5")${RST}"
	parts+=("$seg")
fi
# two weekly buckets: "all other limits" (official payload, % in purple) and
# "fable" (usage endpoint, % in orange); each 7d literal threshold-colored by
# its own utilization
if [ -n "$p7" ]; then
	seg="$(pct_c "$p7")7d${RST} ${PUR}${p7}%${RST}"
	[ -n "$r7" ] && seg="$seg ${DIM}↻ $(fmt_date_hm "$r7")${RST}"
	parts+=("$seg")
fi
if [ -n "$pf" ]; then
	seg="$(pct_c "$pf")7d${RST} ${ORN}${pf}%${RST}"
	[ -n "$rf" ] && seg="$seg ${DIM}↻ $(fmt_date_hm "$rf")${RST}"
	parts+=("$seg")
fi

out="${parts[0]}"
for p in "${parts[@]:1}"; do out+=" ${DIM}•${RST} $p"; done
printf '%s\n' "$out"

# Publish the context window size for ccctx. Claude Code reports the window ONLY
# here, never in the transcript, so anything judging "how full is this session"
# needs it exported — and reading it live means a bigger window on a future model
# is picked up on its own, with no threshold to edit.
#
# Runs after the status line is printed, and every step is allowed to fail: a
# read-only cache dir or a full disk must cost a stale sensor file, never a broken
# status line. Written to a temp file and moved so a reader never sees half a write.
publish_ctx_sensor() {
	[ -n "$session_id" ] && [ -n "$ctx_size" ] || return 0
	local dir tmp
	dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude_ctx"
	[ -d "$dir" ] || mkdir -p "$dir" 2>/dev/null || return 0
	tmp=$(mktemp "${dir}/.${session_id}.XXXXXX" 2>/dev/null) || return 0
	if printf '{"window":%s,"used":%s,"pct":%s,"model":"%s","ts":%s}\n' \
		"$ctx_size" "${ctx_used:-0}" "${ctx_pct:-0}" "$model_id" "$(date +%s)" >"$tmp" 2>/dev/null &&
		mv -f "$tmp" "${dir}/${session_id}.json" 2>/dev/null; then
		return 0
	fi
	rm -f "$tmp" 2>/dev/null
	return 0
}
publish_ctx_sensor
