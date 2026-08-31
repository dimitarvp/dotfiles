# Restoring s1 from this dataset (misc/s1config, mounted at /data/misc/backups/s1config)

Written 2026-08-29. This dataset travels with the pool: on new hardware either
move the disks and `zpool import misc`, or from the old (still-alive) machine
`zfs send -R misc/s1config@<snap> | ssh newbox zfs recv <pool>/s1config`.

The capture layout: `current/etc` (all of /etc), `current/home` (adguard,
pihole, scripts, .ssh, .config, shell files), `current/state` (package list,
enabled units, NM profiles, routing, crontabs, docker inventory),
`current/routers` (both MikroTik exports + binary backups). `LAST_RUN` says
when the capture last succeeded.

## ⚠ Before anything: the duplicate-server trap
Never bring the network-live parts (AdGuard containers, VIPs, the wan2
profile) up while the OLD s1 still runs them — duplicate VIPs and macvlan
IPs will fight on the LAN. The chezmoi `adblock` flag defaults to false on a
fresh machine precisely for this; flip it only at cutover.

## Order of restore
1. Base install (Manjaro), user dimi, packages: `pacman -S --needed - <
   current/state/packages.txt` (review first; AUR bits are not in there).
2. `zpool import misc` (or recv, above).
3. Home: copy `current/home/{scripts,.ssh,.zshrc,.zsh_history}` back; check
   `current/state/crontab_*.txt` and re-install both crontabs. Re-enable the
   capture schedule: s1_capture.service + .timer (in `current/etc` and the
   repo `s1/` dir) → /etc/systemd/system, then
   `systemctl enable --now s1_capture.timer`.
4. chezmoi: `chezmoi init git@github.com:dimitarvp/dotfiles.git`, set
   role/flags in ~/.config/chezmoi/chezmoi.toml per the old machine
   (`adblock=true` ONLY at cutover — see trap above), `chezmoi apply`.
5. Network (/etc pieces, also mirrored in the repo's `s1/` reference dir):
   - /etc/NetworkManager/system-connections/wan1.nmconnection + wan2.nmconnection
     (chmod 600, chown root)
   - /etc/NetworkManager/conf.d/90-no-auto-default-wan2.conf
   - /etc/NetworkManager/conf.d/25-failover.conf
   - /etc/iproute2/rt_tables.d/wan2.conf
   then `systemctl restart NetworkManager`. Verify: `ip route` shows wan1
   metric 100 default + wan2 metric 200 default; `ip rule` shows the
   10100/10101 table-wan2 rules once wan2 has carrier.
6. Docker + AdGuard: `current/home/adguard` back to ~/adguard (contains live
   blue/green conf + query logs + .env with pinned tags), then at cutover:
   `cd ~/adguard && docker compose up -d`. Sidecar rule: after any agh-*
   recreate, force-recreate its keepalived sidecar.
7. PiHole tree (`current/home/pihole`) back to ~/pihole — retired but kept as
   revival insurance; do NOT start it.
8. Routers (only if a router also died): upload `config.backup` via Winbox
   (full restore incl. keys) or paste `export.rsc` sections selectively.
9. Verify battery: dig @192.168.1.96 t.co → 0.0.0.0; dig -b <wan2-ip>
   @192.168.2.1 t.co → 0.0.0.0; curl --interface <wan2-ip> ifconfig.me →
   bulsatcom public IP; nmcli networking connectivity → full.
