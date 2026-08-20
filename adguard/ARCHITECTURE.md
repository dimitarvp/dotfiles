# AdGuard Home on s1 — blue/green with keepalived VIP

Deployed 2026-08-20; chezmoi-managed under the `adblock` data flag (s1 only).

## Topology
- macvlan containers on `enp1s0` (own L2 identities; PiHole's docker-proxy owns host 0.0.0.0:53):
  agh-blue = 192.168.1.97 (VRRP prio 150, normal MASTER), agh-green = .98 (prio 100).
- VIP **192.168.1.96** floats via keepalived sidecars (one per color, sharing the AGH
  container's network namespace). The MikroTik NAT lever targets the VIP.
- aghsync (adguardhome-sync) shares blue's netns: origin blue → replica green, cron */10
  + on-start + API :8080 (basic auth = AGH admin creds). Make hand edits on BLUE (UI/API);
  green converges automatically.
- Admin UI: http://192.168.1.96/ (or .97/.98 per instance), user dimi, password in
  `.admin_password` (chezmoi-encrypted).

## What chezmoi manages vs what is runtime-owned
Managed: this file, docker-compose.yml, keepalived/ (image + configs), agh_rollover.sh,
sync config (encrypted), admin password (encrypted), AdGuardHome.seed.yaml (REFERENCE ONLY).
Runtime-owned — chezmoi must NEVER manage these: `.env` (rollover script rewrites the image
tags), `blue/`, `green/` (live AGH config + query logs + stats; AGH rewrites its own yaml),
`*.rsc` router backups. NEVER edit a live `blue|green/conf/AdGuardHome.yaml` while the
instance runs — it persists in-memory state over your edit. Change via UI/API on blue.
Seed regeneration: `sudo cat blue/conf/AdGuardHome.yaml > AdGuardHome.seed.yaml` (it is a
disaster-recovery reference, not a deployed config).

## Updates
`agh_rollover.sh` (wired into s1's update_all): updates green → health-gates
(dig healthcheck.adguardhome.test via keepalived-green) → VIP abdicates to green
(stop keepalived-blue = VRRP prio-0) → updates blue → blue preempts back → resync.
Measured: ≤2×200ms gaps per rollover. RULE: netns sidecars (keepalived-*, aghsync) wedge
when their parent container is recreated — always `docker compose up -d --force-recreate`
them afterwards (the script does).

## Router (MikroTik, 192.168.1.1)
- NAT lever: "AGH UDP/TCP" (dstnat :53 → .96; src+dst exclude .96-.98 to prevent the
  resolvers' own upstream :53 queries from looping) + "AGH force UDP/TCP" (hairpin
  masquerade) — mirrored next to the PiHole set; swap = disable one set, enable the other.
- Filter: "block DoT/DoQ (AGH project)" reject tcp/udp 853 at top of forward chain.
- DHCP hands out the router (.1) as DNS; the dstnat hijack catches those queries too, so
  the lever moves the whole household. Hijacked flows appear as client "router"
  (hairpin masquerade). PENDING (after pilot): hand out .96 via DHCP for real per-device
  stats; hijack then only catches hardcoded-DNS devices.

## Coexistence
PiHole stays warm and untouched at .99 (own compose at ~/pihole). Both stacks are always
directly queryable from the LAN (intra-LAN traffic never crosses the router).
