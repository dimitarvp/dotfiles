# WSL2 Debian: remote worker setup on Windows 10

Turn a Win10 WSL2 Debian VM into an SSH-accessible dev machine.

## Prerequisites

- Windows 10 with WSL2 enabled
- Debian installed via `wsl --install -d Debian`
- Windows Terminal configured to open Debian by default (optional)

## 1. Enable systemd

In the Debian shell, edit `/etc/wsl.conf`:

```ini
[boot]
systemd=true

[network]
generateResolvConf = false
```

Then in PowerShell: `wsl --shutdown`, reopen Debian.

Verify: `ps -p 1 -o comm=` should say `systemd`.

## 2. Fix DNS

WSL2 auto-generates a broken `/etc/resolv.conf` symlink. Since we set
`generateResolvConf = false` above, replace it:

```bash
sudo rm -f /etc/resolv.conf
echo 'nameserver 192.168.1.99' | sudo tee /etc/resolv.conf
```

(Replace `192.168.1.99` with your DNS server IP.)

## 3. Force IPv4 preference

WSL2 often can't route IPv6, causing apt and other tools to hang. Fix:

```bash
echo 'precedence ::ffff:0:0/96 100' | sudo tee -a /etc/gai.conf
```

## 4. Passwordless sudo

```bash
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USER
```

## 5. Install and start sshd

```bash
sudo apt update && sudo apt install -y openssh-server
sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
```

Add your public key:

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo 'YOUR_PUBLIC_KEY_HERE' >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Start sshd:

```bash
sudo systemctl enable --now ssh
```

## 6. Windows port forwarding

WSL2 has a NAT'd IP (172.x.x.x) that changes on reboot. Windows must
forward port 22 from the host to WSL2.

In **PowerShell as Administrator**:

```powershell
# One-time firewall rule
New-NetFirewallRule -DisplayName "WSL2 SSH" -Direction Inbound -LocalPort 22 -Protocol TCP -Action Allow
```

## 7. Auto-start script (survives reboots)

Create `C:\wsl-ssh-startup.ps1`:

```powershell
Set-Content -Path "C:\wsl-ssh-startup.ps1" -Value 'wsl -d Debian -u root -- service ssh start
$ip = (wsl -d Debian -- hostname -I).Trim().Split(" ")[0]
netsh interface portproxy delete v4tov4 listenport=22 listenaddress=0.0.0.0
netsh interface portproxy add v4tov4 listenport=22 listenaddress=0.0.0.0 connectport=22 connectaddress=$ip'
```

Register as a scheduled task:

```powershell
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File C:\wsl-ssh-startup.ps1"
$trigger = New-ScheduledTaskTrigger -AtLogon
$settings = New-ScheduledTaskSettingsSet
Register-ScheduledTask -TaskName "WSL2 SSH Bridge" -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -Description "Start WSL2 sshd and forward port 22"
```

## 8. Verify

From the host machine (e.g. macOS):

```bash
# Add to /etc/hosts
echo '192.168.1.12 robogamer' | sudo tee -a /etc/hosts

# Add to ~/.ssh/config
Host robogamer
    HostName robogamer
    User dimi
    Port 22
    IdentityFile ~/.ssh/dimi_master

# Test
ssh robogamer echo "it works"
```

## 9. WSL2 backups

**Backup** (PowerShell):

```powershell
wsl --export Debian D:\wsl-backups\debian-YYYYMMDD.tar
```

**Restore** (PowerShell):

```powershell
wsl --unregister Debian
wsl --import Debian <INSTALL_PATH> D:\wsl-backups\debian-YYYYMMDD.tar
```

Find install path via:

```powershell
(Get-ChildItem -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss" | ForEach-Object { Get-ItemProperty $_.PSPath }) | Where-Object { $_.DistributionName -eq "Debian" } | Select-Object -ExpandProperty BasePath
```

## 10. WSL version upgrade

If `wsl --version` doesn't work or systemd doesn't start:

```powershell
wsl --update
wsl --shutdown
```

Then reopen Debian and verify `ps -p 1 -o comm=` says `systemd`.

## Gotchas

- WSL2 IP changes on every reboot — the startup script handles this
- `netsh interface portproxy delete` errors on first run (no existing rule) — harmless
- After `wsl --shutdown`, the startup script must re-run to restore port forwarding
- If apt hangs with "Waiting for headers", check DNS and IPv4 preference (steps 2-3)
- Docker adds a second IP (172.17.0.1); the startup script uses `.Split(" ")[0]` to grab only the WSL2 IP
