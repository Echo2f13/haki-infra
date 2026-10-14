#!/usr/bin/env bash
# Install the Haki host tooling on a Proxmox node. Safe to re-run.
# Usage (as root on the Proxmox host, from a checkout of this repo): bash proxmox/install.sh
set -euo pipefail
cd "$(dirname "$0")"
[[ $EUID -eq 0 ]] || { echo "run as root" >&2; exit 1; }

install -m 0755 sbin/* /usr/local/sbin/

# Hookscripts live on the "local" storage, which must allow snippets.
content=$(pvesh get /storage/local --output-format json | perl -MJSON -0e 'print decode_json(<STDIN>)->{content}')
[[ ,$content, == *,snippets,* ]] || pvesm set local --content "$content,snippets"
install -d /var/lib/vz/snippets
install -m 0755 snippets/haki-isolate.sh /var/lib/vz/snippets/

install -m 0644 systemd/* /etc/systemd/system/
install -m 0644 udev/* /etc/udev/rules.d/
install -m 0644 network/haki-customers /etc/network/interfaces.d/
install -m 0644 sysctl/90-haki.conf /etc/sysctl.d/
install -d -m 0755 /etc/haki
[[ -e /etc/haki/services.conf ]] || install -m 0644 etc/services.conf /etc/haki/
[[ -e /etc/haki/alerts.env ]] || echo "NOTE: create /etc/haki/alerts.env (mode 0600) from etc/alerts.env.example for Discord alerts"

# Key-only SSH: only applied if root already has a key, so this can't lock you out.
if [[ -s /root/.ssh/authorized_keys ]]; then
  install -m 0644 ssh/10-haki-hardening.conf /etc/ssh/sshd_config.d/
  sshd -t && systemctl reload ssh
fi

systemctl daemon-reload
udevadm control --reload
# Firewall before the bridge, so vmbr1 never comes up without isolation.
systemctl enable --now haki-net.service haki-backup-status.timer haki-watch.timer
sysctl -p /etc/sysctl.d/90-haki.conf
ifreload -a
haki-usb-backup --status
echo "Haki host tooling installed."
