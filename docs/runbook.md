# Runbook

All commands run as root on the Proxmox host (Proxmox UI → haki → Shell, or `ssh root@192.168.1.240`).

## New customer

```bash
haki-new <id 201-250> <name> [nano|small|medium]   # e.g. haki-new 202 priya-shop small
pct enter <id>                                     # shell inside it, to set up their app
```

The container gets IP `10.10.0.(id-100)`, starts on boot, and is published to the edge VM
on `192.168.1.240:<20000+id>` → port 80. Apps with no website (bots, workers) don't need that:
`haki-net remove <20000+id>`.

### Give it a public hostname
On the edge VM (`ssh root-host@192.168.1.34`), add above the final 404 rule in
`/etc/cloudflared/config.yml`:

```yaml
  - hostname: <name>.<domain>
    service: http://192.168.1.240:<20000+id>
```
then:
```bash
sudo cloudflared tunnel route dns kotamanish <name>.<domain>
sudo systemctl restart cloudflared
```

## Remove a customer

```bash
pct stop <id> && pct destroy <id> --purge 1
haki-net remove <20000+id>
```
Their backups stay on the USB drive until pruned.

## Network

```bash
haki-net list      # published ports
haki-net check     # validate rules without applying
haki-net apply     # reload rules (also runs at boot)
nft list table inet haki
```

## Backups

- **Run one:** plug in the USB drive. Watch Notes, or `journalctl -fu haki-usb-backup`.
- **Status:** Proxmox UI → haki → Notes. `haki-usb-backup --status` refreshes it.
- **Use another drive:** add a line to `/etc/udev/rules.d/99-haki-usb-backup.rules` with its
  UUID (`lsblk -o NAME,FSTYPE,UUID`), set `UUID=` in `haki-usb-backup`, and create a `Server`
  folder on it. The script never writes outside `Server/`.

### Restore
Plug in the drive and wait for the automatic backup to finish (it skips if one ran in the last
12 h). Then:

```bash
mount -t exfat UUID=83F6-DBB2 /mnt/haki-usb-backup
ls /mnt/haki-usb-backup/Server/proxmox/
qmrestore /mnt/haki-usb-backup/Server/proxmox/vzdump-qemu-<id>-<date>.vma.zst <id> --storage local-lvm --force
pct restore <id> /mnt/haki-usb-backup/Server/proxmox/vzdump-lxc-<id>-<date>.tar.zst --storage local-lvm --force
umount /mnt/haki-usb-backup
```
`--force` overwrites the existing guest with that id; restore to a new id to compare first.

## Updates (monthly)

1. Plug in the backup drive, or run `haki-usb-backup --now` with it attached.
2. Host: `apt update && apt -s full-upgrade` to preview, then `apt full-upgrade`.
3. Edge VM (`ssh root-host@192.168.1.34`): `sudo apt full-upgrade`.
4. Reboot the host from the web UI (haki → Reboot). Guests start in order: VM 100, VM 101 (+30 s), containers.

**Kernel pin:** the host is pinned to `6.17.13-21-pve` (`proxmox-boot-tool kernel list`). Proxmox's
default moved to the 7.0 series; try it only when you can reach the machine's screen:
`proxmox-boot-tool kernel unpin`, reboot, and check GPU passthrough (`curl 192.168.1.35:11434/api/ps`
after loading a model shows `size_vram` > 0). If it fails, pick 6.17.13 under GRUB → Advanced options
and pin it again.

**SSH is key-only** on the host and the edge VM. Use the Proxmox web UI shell/console if a key is lost.

## Rebuild the host from scratch

1. Install Proxmox VE on the SSD, same IP (192.168.1.240).
2. Clone this repo and run `bash proxmox/install.sh`.
3. Restore VMs and containers from the USB drive (above).
4. Host settings that aren't in this repo are in the `host-config-*.tar.gz` on the drive.
