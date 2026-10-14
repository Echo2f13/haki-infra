# haki-infra

Infrastructure for **Haki**, a small hosting service run on a home Proxmox server.
This repo is the source of truth for everything installed on the host; secrets and
customer data are never stored here.

## Architecture

```
Internet ── Cloudflare (DNS, TLS, CDN) ── Cloudflare Tunnel (outbound only; works behind CGNAT)
                                              │
Proxmox host "haki" (i5-8400, 6 cores · 16 GB RAM · 480 GB SSD)   192.168.1.240
 │
 ├─ vmbr0  home LAN 192.168.1.0/24 ── your devices, Proxmox UI, router
 │    ├─ VM 100  edge  (192.168.1.34)  cloudflared + nginx, kotamanish.dev, GitHub runner
 │    └─ VM 101  ollama (GPU passthrough)
 │
 └─ vmbr1  customer network 10.10.0.0/24 (no physical port, NAT out via the host)
      ├─ CT 201  lalith-bot  10.10.0.101
      └─ CT 2xx  ...         10.10.0.(id-100)
```

**Customer isolation** (`haki-net`, nftables table `inet haki`):

| From a customer container to… | |
|---|---|
| Internet (HTTP/S, DNS, anything else) | allowed |
| Home LAN, router, edge VM, any private range | blocked |
| Proxmox host (UI 8006, SSH) | blocked |
| Other customers | blocked (bridge port isolation, `haki-isolate.sh`) |
| Outbound SMTP (25) | blocked |

Inbound: only the edge VM can reach a customer, through `192.168.1.240:<20000+id>`
→ `10.10.0.(id-100):80`. Public hostnames are added to the tunnel on the edge VM.

**Backups** (`haki-usb-backup`): plugging in the USB drive (exFAT, UUID `83F6-DBB2`)
backs up every VM and container plus host config to `Server/proxmox/` on the drive,
keeps 4 of each, then unmounts. Status and overdue warnings (7 days) appear in
Proxmox → haki → Notes.

## Plans

| Plan | CPU | RAM | Disk |
|---|---|---|---|
| nano | 0.25 core | 256 MB | 5 GB |
| small | 0.5 core | 512 MB | 10 GB |
| medium | 1 core | 1 GB | 20 GB |

## Layout

| Path | Installed to |
|---|---|
| `proxmox/sbin/` | `/usr/local/sbin/` — `haki-new`, `haki-net`, `haki-usb-backup` |
| `proxmox/snippets/` | `/var/lib/vz/snippets/` — container hookscript |
| `proxmox/systemd/`, `udev/`, `network/`, `sysctl/` | matching `/etc` paths |
| `proxmox/install.sh` | installs all of the above (idempotent) |
| `tenants/<name>/` | per-customer service files (no secrets) |

The edge VM's tooling (nginx, cloudflared, deploy scripts) lives in
[Echo2f13/portfolio_main](https://github.com/Echo2f13/portfolio_main) under `deploy/server/`.

Day-to-day commands are in [docs/runbook.md](docs/runbook.md).
