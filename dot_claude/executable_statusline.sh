#!/usr/bin/env bash
# statusline.sh — Claude Code status line.
# Reads session JSON on stdin, prints:
#   cwd • model • effort • ctx • 5h limit • 7d all-other • 7d fable
# rate_limits is absent until the session's first API response; parts degrade away.
# The Fable weekly bucket is NOT in the statusline payload (CC <=2.1.216) — it is
# fetched from Anthropic's undocumented OAuth usage endpoint (same source as
# /usage), cached 120s in ~/.cache, degrading to omission on any failure.

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
	(.context_window.used_percentage         | if type == "number" then round | tostring else "" end)
' <<<"$input")

# GNU vs BSD date (robeast is macOS)
if [ "$(uname)" = Darwin ]; then
	IS_DARWIN=1
	epoch_fmt() { date -r "$1" "+$2"; }
else
	IS_DARWIN=0
	epoch_fmt() { date -d "@$1" "+$2"; }
fi

# Fable weekly limit via the OAuth usage endpoint, cached. Token is read fresh
# per fetch (CC rotates it) and passed via curl --config stdin, never argv.
# On fetch failure the cache mtime is bumped (or a stub written) so a dead
# endpoint is retried at most every 120s instead of every render.
USAGE_CACHE="$HOME/.cache/claude_usage_limits.json"
fetch_usage() {
	local now age tok tmpf
	now=$(date +%s)
	if [ -f "$USAGE_CACHE" ]; then
		if [ "$IS_DARWIN" = 1 ]; then age=$(( now - $(stat -f %m "$USAGE_CACHE" 2>/dev/null || echo 0) ))
		else age=$(( now - $(stat -c %Y "$USAGE_CACHE" 2>/dev/null || echo 0) )); fi
		[ "$age" -lt 120 ] && return 0
	fi
	tok=$(jq -r '.claudeAiOauth.accessToken // empty' "$HOME/.claude/.credentials.json" 2>/dev/null)
	[ -n "$tok" ] || return 0
	tmpf=$(mktemp "${TMPDIR:-/tmp}/clusage.XXXXXX") || return 0
	if curl -sf --max-time 2 -o "$tmpf" --config /dev/stdin <<EOF
url = "https://api.anthropic.com/api/oauth/usage"
header = "Authorization: Bearer $tok"
header = "anthropic-beta: oauth-2025-04-20"
EOF
	then
		mkdir -p "$HOME/.cache"
		mv "$tmpf" "$USAGE_CACHE" && chmod 600 "$USAGE_CACHE"
	else
		rm -f "$tmpf"
		if [ -f "$USAGE_CACHE" ]; then touch "$USAGE_CACHE"
		else mkdir -p "$HOME/.cache" && printf '{}' > "$USAGE_CACHE" && chmod 600 "$USAGE_CACHE"; fi
	fi
}

fetch_usage
pf="" rf=""
if [ -f "$USAGE_CACHE" ]; then
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
