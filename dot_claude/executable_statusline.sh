#!/usr/bin/env bash
# statusline.sh — Claude Code status line.
# Reads session JSON on stdin, prints: cwd • model • effort • 5h limit • 7d limit
# rate_limits is absent until the session's first API response; parts degrade away.

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
	epoch_fmt() { date -r "$1" "+$2"; }
else
	epoch_fmt() { date -d "@$1" "+$2"; }
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
if [ -n "$p7" ]; then
	seg="$(pct_c "$p7")7d ${p7}%${RST}"
	[ -n "$r7" ] && seg="$seg ${DIM}↻ $(fmt_date_hm "$r7")${RST}"
	parts+=("$seg")
fi

out="${parts[0]}"
for p in "${parts[@]:1}"; do out+=" ${DIM}•${RST} $p"; done
printf '%s\n' "$out"
