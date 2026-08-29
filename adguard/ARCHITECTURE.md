# AdGuard Home on s1 — blue/green with keepalived VIP

Deployed 2026-08-20; chezmoi-managed under the `adblock` data flag (s1 only).

## Topology
- macvlan containers on `enp1s0` (own L2 identities; PiHole's docker-proxy owns host 0.0.0.0:53):
  agh-blue = 192.168.1.97 (VRRP prio 150, normal MASTER), agh-green = .98 (prio 100).
- VIP **192.168.1.96** floats via keepalived sidecars (one per color, sharing the AGH
  container's network namespace). The MikroTik NAT lever targets the VIP.
- THIRD VRRP member: the MikroTik itself (prio 50) — if s1 dies entirely, the router claims
  .96 in ~1-2s and its own resolver (same ISP upstreams, unfiltered) answers until s1
  returns and blue preempts back. See "Router" below. Dialect is VRRPv3 multicast 300ms
  no-auth EVERYWHERE — keepalived configs and the router must stay in lockstep; never
  re-add unicast_peer to keepalived (RouterOS speaks multicast VRRP only).
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

## Primary router (cooolBox MikroTik, 192.168.1.1)
- NAT lever: "AGH UDP/TCP" (dstnat :53 → .96; src+dst exclude .96-.98 to prevent the
  resolvers' own upstream :53 queries from looping) + "AGH force UDP/TCP" (hairpin
  masquerade) — mirrored next to the PiHole set; swap = disable one set, enable the other.
- Filter: "block DoT/DoQ (AGH project)" reject tcp/udp 853 at top of forward chain.
- VRRP fallback (added 2026-08-23): `/interface vrrp` "vrrp-agh-dns" on bridge, vrid 96,
  prio 50, version 3, interval 300ms + `/ip address 192.168.1.96/24` on it (active only
  while master). The interface MUST be a member of interface-list LAN: input rule 6 drops
  non-LAN traffic, and queries to the VIP's virtual MAC (00:00:5E:00:01:60) arrive on the
  vrrp interface, NOT the bridge — heartbeats arrive on the bridge, so VRRP can work while
  DNS is silently dropped (verified failure mode 2026-08-23). Rehearsal: stop both
  keepalived sidecars → router MASTER ~1-2s, DNAT + direct paths both answer (unfiltered);
  start them → blue back MASTER sub-second, filtering restored.
- DHCP hands out the router (.1) as DNS; the dstnat hijack catches those queries too, so
  the lever moves the whole household. Hijacked flows appear as client "router"
  (hairpin masquerade). PENDING (after pilot): hand out .96 via DHCP for real per-device
  stats; hijack then only catches hardcoded-DNS devices.

## Second network (bulsatcom LAN, added 2026-08-29)
- The same blue/green pair also serves 192.168.2.0/24 (the Bulsatcom uplink's LAN) through
  a second macvlan (`aghnet2`, parent = the USB NIC enp0s20f0u3u2): blue = 192.168.2.97,
  green = .98, VIP **192.168.2.96** as a second vrrp_instance (AGH_NET2) in the same
  keepalived sidecars — same vrid 96 (valid: VRID scope is per-link and the two LANs are
  separate L2 domains), same 150/100/50 priority ladder, same health script for both
  instances (one AGH process serves both nets, so one health truth).
- Container interface names are PINNED via compose `interface_name:` (net1/net2) and the
  keepalived configs reference net1/net2 — kernel eth0/eth1 order is a RACE with multiple
  networks (blue came up cross-wired on the first net2 deploy). Never reference ethN.
- The containers' default route stays on net1 (compose attach `priority: 100` on aghnet);
  net2 clients are answered over net2's connected subnet. Non-DNS egress (blocklist
  downloads, update checks) follows the default route and pauses while cooolbox is down.
- Upstream diversity (2026-08-29): upstream_dns = both ISPs' resolvers (cooolbox
  84.22.22.48/.84 + bulsatcom 212.39.90.42/.43), upstream_mode=parallel (all four asked,
  fastest answer wins). Each ISP's pair is pinned to its own uplink via /32 routes
  installed by the keepalived sidecars' post_start hooks — ISP resolvers answer on-net
  only (verified: bulsatcom's time out when routed via cooolbox). Either uplink dying
  leaves FULL-capacity resolution for both LANs via the survivor (drill: cooolbox
  resolvers rerouted dead → uncached answer in 116ms through bulsatcom). If the resolver
  IPs ever change, update BOTH the compose post_start hooks and AGH's upstream list.
- AGH `allowed_clients` = 192.168.1.0/24 + 192.168.2.0/24 + 127.0.0.1 (set via API on both
  instances). A source outside the list is REFUSED silently — symptom: dig timeouts from
  that subnet while everything else looks healthy.
- Bulsatcom router (RB2011UiAS-2HnD, RouterOS 7.23.2, 192.168.2.1): same rule set as the
  primary — "AGH UDP/TCP" dstnat :53 → 2.96 (src+dst exclude 2.96-2.98), "AGH force
  UDP/TCP" hairpin masquerade, "block DoT/DoQ (AGH project)" reject 853 placed BEFORE the
  defconf fasttrack rule, vrrp-agh-dns on bridge (vrid 96, prio 50, 300ms) + 192.168.2.96/24
  on it. Its input chain has no LAN interface-list rule (default-accept policy), so the
  cooolBox vrrp/interface-list gotcha does not apply. DHCP still hands out 2.1 as DNS; the
  hijack catches those queries (lever semantics identical to net1). Pre-change backups:
  bulsatcom_preagh_20260829.{rsc,backup} in ~/adguard/. SSH: key-only (dimi_master), host
  alias `bulsatcom` (from non-net2 machines it hops via s1 automatically).
- s1's host cannot reach the 2.96-2.98 macvlan children directly (same isolation as net1);
  test via the router path: `dig -b 192.168.2.99 @192.168.2.1 t.co` (0.0.0.0 = filtering
  live) — the hairpin masquerade makes the reply routable.

## The macvlan shim (added 2026-08-29, TS/HS rehearsal finding)
By macvlan design the s1 HOST could never reach its own AGH children (.96/.97/.98) —
fine for LAN clients, fatal for the Tailscale subnet-router role (roaming devices'
DNS must transit s1's kernel INTO the VIP). Fix: NM connection `aghshim` — a macvlan
sidecar interface on enp1s0 (bridge mode) holding 192.168.1.95/32 plus /32 routes to
.96/.97/.98 via it. Children↔shim are macvlan siblings, so traffic flows. Side effect:
s1 itself can finally query the VIP (`dig @192.168.1.96` works on-host now). Subnet-
routed roaming traffic is SNATed to the shim IP, so AGH logs roamers as client
192.168.1.95 (per-roamer identity = optional later upgrade: --snat-subnet-routes=false
+ 100.64.0.0/10 routes back via the shim in the AGH containers + router static routes).
Reference copy: repo s1/etc/NetworkManager/system-connections/aghshim.nmconnection.

## Coexistence
PiHole RETIRED 2026-08-23 (pilot passed): container and network removed via
`docker-compose down`, image still auto-updated by s1 update_all's pull-only line, config
bind-mounts intact under ~/pihole. Revive = `cd ~/pihole && docker-compose up --detach
pihole` + router lever swap. AGH instances remain directly queryable from the LAN
(intra-LAN traffic never crosses the router).
