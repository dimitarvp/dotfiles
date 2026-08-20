#!/bin/bash
# agh_rollover — blue/green AdGuard Home update with keepalived VIP handover.
# Green (backup) updates first, then the VIP abdicates to green while blue
# updates, then blue preempts back. Sidecars (keepalived-*, aghsync) share
# their parent's netns and MUST be force-recreated after the parent is
# recreated, or they wedge in the dead namespace.
# Usage: agh_rollover.sh [--force]   (--force rolls even when already latest,
#         and force-recreates the AGH containers — full-fidelity rehearsal)
set -euo pipefail
cd /home/dimi/adguard
say() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }

latest=$(curl -sf https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest | jq -r .tag_name)
[ -n "$latest" ] && [ "$latest" != "null" ] || { echo "ERROR: could not resolve latest AGH release" >&2; exit 1; }
. ./.env
if [ "${1:-}" != "--force" ] && [ "$AGH_TAG_BLUE" = "$latest" ] && [ "$AGH_TAG_GREEN" = "$latest" ]; then
	say "AdGuard Home already at $latest — nothing to do"; exit 0
fi
FR=""; [ "${1:-}" = "--force" ] && FR="--force-recreate"
say "rolling to $latest (blue=$AGH_TAG_BLUE green=$AGH_TAG_GREEN)${FR:+ [forced recreate]}"
docker pull -q "adguard/adguardhome:$latest" >/dev/null

# keepalived-green survives the whole flow — it is the probe vehicle.
probe() { docker exec keepalived-green dig +time=1 +tries=1 @"$1" healthcheck.adguardhome.test A >/dev/null 2>&1; }
gate() { # $1 ip  $2 label
	for _ in $(seq 1 30); do probe "$1" && { say "$2 healthy"; return 0; }; sleep 2; done
	echo "ERROR: $2 failed health gate — VIP untouched, investigate" >&2; exit 1
}

say "phase 1: update green (backup — no traffic impact)"
sed -i "s/^AGH_TAG_GREEN=.*/AGH_TAG_GREEN=$latest/" .env
docker compose up -d $FR agh-green >/dev/null 2>&1
docker compose up -d --force-recreate keepalived-green >/dev/null 2>&1
gate 192.168.1.98 "green ($latest)"

say "phase 2: VIP handover to green (keepalived graceful abdication)"
docker stop keepalived-blue >/dev/null
sleep 2
gate 192.168.1.96 "VIP on green"

say "phase 3: update blue"
sed -i "s/^AGH_TAG_BLUE=.*/AGH_TAG_BLUE=$latest/" .env
docker compose up -d $FR agh-blue >/dev/null 2>&1
docker compose up -d --force-recreate keepalived-blue aghsync >/dev/null 2>&1
gate 192.168.1.97 "blue ($latest)"

say "phase 4: blue preempts VIP back (prio 150) once its checker passes"
sleep 10
gate 192.168.1.96 "VIP after preempt-back"
say "resync green from blue"
PW=$(cat .admin_password)
synced=""
for _ in 1 2 3 4; do
	curl -sf -u "dimi:$PW" -X POST http://192.168.1.97:8080/api/v1/sync >/dev/null && { synced=1; break; }
	sleep 5
done
[ -n "$synced" ] && say "sync triggered" || say "WARN: sync trigger failed 4x (cron will catch up)"
say "done: blue=$(docker inspect agh-blue --format '{{.Config.Image}}') green=$(docker inspect agh-green --format '{{.Config.Image}}')"
