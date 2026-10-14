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
 │    ├─ VM 100  edge   (192.168.1.34)  2 GB · cloudflared + nginx, kotamanish.dev, GitHub runner
 │    └─ VM 101  ollama (192.168.1.35)  4 GB · 4 cores (low CPU priority) · GTX 1050 Ti 4 GB passthrough
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

**ollama sizing** (measured, ctx 4096): 1–2B models fit fully in VRAM (1.1–1.9 GB, 33–38 tok/s);
7B Q4_K_M models use 3.0 GB VRAM + 2.1 GB system RAM (~10 tok/s), one at a time.
4 GB RAM covers the worst case. With passthrough, the VM's RAM is always fully reserved on the host.

Boot order after a power cut: VM 100 first, then VM 101 (30 s later), then customer containers.

**Monitoring** — alerts go to a Discord channel (webhook in `/etc/haki/alerts.env` on the host and
the `HAKI_DISCORD_WEBHOOK` repo secret; never committed):

- `haki-watch` (host, every 2 min): public site, guests set to start on boot, ollama API, customer
  services in `/etc/haki/services.conf`, host disk / storage pool / RAM / failed services / SSD SMART,
  customer firewall loaded, USB backup older than 8 days. Alerts on DOWN, every 12 h while down,
  and on RECOVERED.
- `.github/workflows/watchdog.yml` (GitHub, every ~10 min): checks kotamanish.dev from outside,
  so you still hear about it when the whole house is offline. GitHub pauses scheduled workflows
  after 60 days without repo activity — re-enable under Actions if that happens.

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
