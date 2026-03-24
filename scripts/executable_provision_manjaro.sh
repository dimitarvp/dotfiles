#!/bin/bash
# --------------------------------------------------
# Provision a Manjaro Linux development machine.
#
# Run AFTER the Manjaro installer; this does NOT install the OS.
# Before running, copy shared SSH keys from a secure source:
#   cp /media/usb/dimi* ~/.ssh/ && chmod 400 ~/.ssh/dimi*
# Then shred the source:
#   shred -f -n 3 -u -v -z /media/usb/dimi*
# --------------------------------------------------

set -euox pipefail

USER=$(whoami)
INSTALL='yay -S --noconfirm --needed'
TIMEZONE='Europe/Sofia'

# ==== Phase 1: System setup ====

if ! sudo grep -qF "$USER ALL = (ALL) NOPASSWD:ALL" /etc/sudoers; then
	echo "$USER ALL = (ALL) NOPASSWD:ALL" | sudo tee --append /etc/sudoers
fi

mkdir -p ~/bin ~/scripts

sudo systemctl enable fstrim.timer
sudo systemctl enable avahi-daemon
sudo usermod "$USER" -aG wheel

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
OnBootSec=5
OnUnitActiveSec=1h

[Install]
WantedBy=timers.target
TZEOF
sudo tee /etc/systemd/system/tz-update-resume.service >/dev/null <<'TZEOF'
[Unit]
Description=Update timezone after resume
After=suspend.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'sleep 10 && TZ=$(curl -sf --max-time 10 https://ipapi.co/timezone) && [ -n "$TZ" ] && timedatectl set-timezone "$TZ"'

[Install]
WantedBy=suspend.target
TZEOF
sudo systemctl daemon-reload
sudo systemctl enable --now tz-update.timer
sudo systemctl enable tz-update-resume.service

sudo pacman-mirrors --fasttrack && sudo pacman -Syyu --noconfirm
sudo pacman -S --noconfirm --needed yay
$INSTALL pacman-contrib

sudo timedatectl set-ntp true
sudo timedatectl set-timezone "$TIMEZONE"
sudo systemctl enable --now systemd-timesyncd.service

# ==== Phase 2: SSH ====

$INSTALL openssh
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

for entry in s1:s1 robeast:robeast robogamer:robogamer; do
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

# ==== Phase 3: Core bootstrap tools ====

$INSTALL base-devel make gcc git cmake curl wget zsh vim neovim \
	chezmoi direnv fzf fzy peco pick github-cli \
	pkg-config pkgconf fop unzip xclip wl-clipboard bind \
	inotify-tools extra/wxwidgets-gtk3 extra/webkit2gtk-4.1 \
	extra/mold jemalloc jq python-pynvim

# ==== Phase 4: Rust toolchain ====

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs |
	sh -s -- -y --no-modify-path --default-toolchain stable -c clippy rust-docs rust-src
export PATH="$PATH:$HOME/.cargo/bin"
rustup target add wasm32-unknown-unknown --toolchain stable
cargo install cargo-binstall

# Minimal Rust tools needed for zsh config to work
cargo binstall -y bat eza fd-find git-delta mise ripgrep sccache zoxide

# ==== Phase 5: Go (managed by mise, not pacman) ====

mise install go@latest
export PATH="$PATH:$HOME/go/bin"
go install github.com/nao1215/gup@latest

# ==== Phase 6: Dotfiles ====

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

# ==== Phase 10: System CLI tools (non-Rust, non-Go — those are handled above) ====

$INSTALL \
	ack aria2 asciidoc atomicparsley aws-cli-v2 aws-session-manager-plugin \
	bfg bloaty bmon borg btop cmatrix csvkit ctop curlie \
	darkhttpd dbmate diff-so-fancy difftastic dive \
	docker docker-buildx docker-compose dool duckdb duf \
	esbuild ffmpeg fio fx gallery-dl gdu \
	git-filter-repo git-lfs glances glow gnuplot graphviz gron \
	hey hstr htop httrack imgcat \
	jc jnettop kopia lazydocker lazygit lbzip2 lnav \
	lua luajit luarocks mediainfo miller moreutils multitail \
	ncdu nmap openapi-generator p7zip parallel pdfgrep pigz \
	pkgfile plumber pngquant procs progress pspg pv \
	python-pipx python-pygments \
	rclone rename restic ruby \
	sc-im scdoc selene shellcheck shfmt smartmontools source-highlight \
	streamlink swagger-codegen syncthing \
	the_silver_searcher tigervnc timg tldr tree tree-sitter ttyplot typescript \
	ugrep up visidata w3m wget wrk xh xmlstarlet \
	you-get youtubedr yq yt-dlp zenith zpaq

# ==== Phase 11: AUR packages ====

$INSTALL earthly-bin exercism-bin noti repomix semgrep-bin tabula

# ==== Phase 12: Databases ====

$INSTALL postgresql redis mongodb-bin
sudo systemctl enable --now postgresql redis
sudo -u postgres createuser -s "$(whoami)"

# ==== Phase 13: Docker ====

sudo systemctl enable --now docker.service
sudo usermod "$USER" -aG docker
# NOTE: docker group requires logout

# ==== Phase 14: Fonts ====

$INSTALL \
	ttf-ubuntu-mono-nerd ttf-ms-fonts powerline-fonts ttf-symbola \
	noto-fonts-emoji ttf-twemoji ttf-twemoji-color otf-openmoji \
	extra/ttf-cascadia-mono-nerd
fc-cache -fv

# ==== Phase 15: UI applications ====

$INSTALL alacritty enpass telegram-desktop firefox librewolf-bin \
	streamlink-twitch-gui-bin mpv valentina-studio zulip-desktop-bin \
	seahorse

# ==== Done ====

cat <<'NOTES'

=== Post-install checklist ===
1. Log out and back in (zsh + docker group)
2. Run `seahorse` and set keyring password = user password
3. Add keyboard layouts and adjust repeat rate
4. Add SSH public key to GitHub/GitLab/Sourcehut
5. Authenticate: gh auth login
6. Adjust power settings / screen timeout
7. Rebuild zsh completions: rm ~/.cache/zsh/.zcompdump-* && exec zsh
NOTES
