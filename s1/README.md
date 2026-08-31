# s1 reference copies

This directory is chezmoi-ignored on every machine (see .chezmoiignore). It
exists so the declarative core of s1's system-level config — the files that
live OUTSIDE $HOME and therefore outside chezmoi's normal reach — survives
even if s1 and its ZFS pool die together.

Deployment: the systemd units and the panic sysctl AUTO-DEPLOY on s1 via the
repo's run_onchange_after_deploy-s1-etc script (re-fires when their content
changes); the network files stay MANUAL, per RESTORE.md (also captured nightly, with everything
else, into s1's dataset misc/s1config — mounted at /data/misc/backups/s1config —
by scripts/s1_capture — systemd timer 00:45 (Persistent=true catches runs missed
while the box was down), snapshot only when something changed).

Live truth = the real files on s1. Update these copies when those change:
- etc/NetworkManager/system-connections/wan1|wan2.nmconnection — dual-WAN
  profiles (wan2 = route-table-101 isolation + metric-200 main fallback)
- etc/NetworkManager/conf.d/90-no-auto-default-wan2.conf — blocks NM
  auto-profile regeneration for the USB NIC (scoped to its MAC)
- etc/NetworkManager/conf.d/25-failover.conf — 30s connectivity checks
  against cp.cloudflare.com with empty expected response (204-friendly);
  drives the automatic wan1→wan2 egress failover (+20000 metric penalty)
- etc/iproute2/rt_tables.d/wan2.conf — names table 101 "wan2"
- etc/systemd/system/s1_capture.service + .timer — the capture schedule
- etc/sysctl.d/90-panic-reboot.conf — auto-reboot on kernel panic/oops
- scripts/s1_capture — the nightly capture script itself
