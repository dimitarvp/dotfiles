#!/bin/bash
# --------------------------------------------------
# Provision a Debian (unstable/sid) WSL2 development machine.
#
# Run AFTER WSL2 setup; this does NOT install the OS.
# Prerequisites:
#   - SSH key (dimi_master) already in ~/.ssh/authorized_keys
#   - Passwordless sudo already configured
#   - WSL2 backup taken: wsl --export Debian D:\wsl-backups\debian-YYYYMMDD.tar
#
# Run phases one by one or all at once.
# --------------------------------------------------

set -euox pipefail

USER=$(whoami)
INSTALL='sudo apt install -y'
TIMEZONE='Europe/Sofia'

# ==== Phase 1: System setup ====

sudo apt update && sudo apt upgrade -y

mkdir -p ~/bin ~/scripts

sudo timedatectl set-timezone "$TIMEZONE"
# NOTE: WSL2 syncs time from Windows host; no timesyncd needed

# Automatic timezone from IP geolocation (no GeoClue dependency)
sudo tee /etc/systemd/system/tz-update.service >/dev/null <<'TZEOF'
[Unit]
Description=Update timezone from IP geolocation
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'TZ=$(curl -sf --max-time 10 https://ipapi.co/timezone) && [ -n "$TZ" ] && timedatectl set-timezone "$TZ"'
TZEOF
sudo tee /etc/systemd/system/tz-update.timer >/dev/null <<'TZEOF'
[Unit]
Description=Periodic timezone update

[Timer]
OnBootSec=30
OnUnitActiveSec=1h

[Install]
WantedBy=timers.target
TZEOF
sudo systemctl daemon-reload
sudo systemctl enable --now tz-update.timer

# ==== Phase 2: Core bootstrap tools ====

$INSTALL \
	build-essential make gcc git cmake curl wget zsh vim neovim \
	direnv fzf gh \
	pkg-config libssl-dev libclang-dev libwxgtk3.2-dev libwebkit2gtk-4.1-dev \
	libncurses-dev libgl1-mesa-dev libglu1-mesa-dev libpng-dev libssh-dev \
	libxml2-dev libxml2-utils unixodbc-dev autoconf m4 xsltproc fop default-jdk \
	mold libjemalloc-dev unzip xclip jq rsync npm \
	bind9-dnsutils inotify-tools python3-pynvim

# ==== Phase 3: SSH ====

$INSTALL openssh-client
ssh-keygen -q -t ed25519 -N '' -f ~/.ssh/id_ed25519 <<<y >/dev/null 2>&1
touch ~/.ssh/config
chmod 600 ~/.ssh/config

for entry in github.com:dimi_github gitlab.com:dimi_gitlab git.sr.ht:dimi_srht; do
	host="${entry%%:*}"
	key="${entry##*:}"
	if ! grep -qF "Host $host" ~/.ssh/config; then
		cat <<SSHC >>~/.ssh/config

Host $host
    HostName $host
    IdentityFile ~/.ssh/$key
SSHC
	fi
done

for entry in s1:s1 robotko:robotko robeast:robeast; do
	host="${entry%%:*}"
	hostname="${entry##*:}"
	if ! grep -qF "Host $host" ~/.ssh/config; then
		cat <<SSHC >>~/.ssh/config

Host $host
    HostName $hostname
    User $USER
    Port 22
    IdentityFile ~/.ssh/dimi_master
SSHC
	fi
done

# ==== Phase 4: Rust toolchain ====

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs |
	sh -s -- -y --no-modify-path --default-toolchain stable -c clippy,rust-docs,rust-src
export PATH="$PATH:$HOME/.cargo/bin"
rustup target add wasm32-unknown-unknown --toolchain stable
cargo install cargo-binstall

# Minimal Rust tools needed for zsh config and chezmoi secrets to work
cargo binstall -y bat eza fd-find git-delta mise rage ripgrep sccache zoxide

# ==== Phase 5: Go (managed by mise) ====

mise install go@latest
mise use go
eval "$(mise activate bash --shims)"
export GOBIN="$HOME/go/bin"
export PATH="$PATH:$HOME/go/bin"
go install github.com/nao1215/gup@latest

# ==== Phase 6: Dotfiles ====

sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
chezmoi init dimitarvp --apply
# Deploys: crates.conf, gup.json, .zshrc, all configs, scripts

# ==== Phase 7: Shell ====

sudo chsh -s /bin/zsh "$USER"
touch ~/.zsh/secrets.zsh
# NOTE: log out and back in for zsh to take effect

# ==== Phase 8: Full tool installation ====

# Rust tools (source of truth: ~/.config/cargo-crates/crates.conf)
~/scripts/cargo_converge

# Go tools (source of truth: ~/.config/gup/gup.json)
~/scripts/gup_converge

# ==== Phase 9: Language runtimes (mise) ====

export KERL_CONFIGURE_OPTIONS='--without-odbc'
mise install -y

# ==== Phase 10: System CLI tools (non-Rust, non-Go) ====

$INSTALL \
	ack aria2 asciidoc atomicparsley \
	bmon borgbackup btop csvkit \
	esbuild ffmpeg fio \
	git-filter-repo git-lfs gnuplot graphviz gron \
	htop httrack \
	jc jnettop lbzip2 lnav \
	lua5.4 luajit luarocks mediainfo miller moreutils multitail \
	ncdu nmap p7zip-full parallel pdfgrep pigz \
	pngquant progress pspg pv \
	pipx python3-pygments \
	rclone rename restic ruby \
	sc-im shellcheck shfmt smartmontools \
	syncthing \
	silversearcher-ag timg tealdeer tree ttyplot \
	ugrep visidata w3m wget wrk xh xmlstarlet \
	yq yt-dlp zpaq
# NOTE: bfg, curlie, darkhttpd, dbmate, duckdb, fx not in Debian repos
# curlie, dbmate, fx available via gup_converge (Go tools)

# AWS CLI v2 (not in Debian repos)
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -qo /tmp/awscliv2.zip -d /tmp
sudo /tmp/aws/install
rm -rf /tmp/awscliv2.zip /tmp/aws

# AWS Session Manager Plugin (not in Debian repos)
curl -sf "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o /tmp/session-manager-plugin.deb
sudo dpkg -i /tmp/session-manager-plugin.deb
rm -f /tmp/session-manager-plugin.deb

# ==== Phase 11: Databases ====

$INSTALL postgresql redis
sudo systemctl enable --now postgresql redis-server
sudo -u postgres createuser -s "$(whoami)"

# ==== Phase 12: Docker (official repo, not Debian's) ====

# Debian unstable's docker.io/containerd packages break on rolling updates.
# Use Docker's official repo with bookworm (stable) target — binaries are
# statically linked and work fine on sid.
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt update
$INSTALL docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo /usr/sbin/usermod "$USER" -aG docker
# NOTE: docker group requires logout
sudo systemctl enable --now docker.service

# ==== Done ====

cat <<'NOTES'

=== Post-install checklist ===
1. Log out and back in (zsh + docker group)
2. Copy dimi_master key to this machine for outbound SSH
3. Add SSH public key to GitHub/GitLab/Sourcehut
4. Authenticate: gh auth login
5. Verify: chezmoi apply works, cargo_converge and gup_converge completed
6. Rebuild zsh completions: rm ~/.cache/zsh/.zcompdump-* && exec zsh
NOTES
