# Haki — status and next steps

_Last updated: 15 Oct 2026. Read this first when resuming work on Haki._

Haki is a small paid hosting service (working name; domain **hakirun.com**, not bought yet) run on
the home Proxmox server. Goal: host other people's sites and apps for money, priced pay-as-you-go
with a prepaid wallet.

## Where things stand

| Area | State |
|---|---|
| Proxmox host `haki` (192.168.1.240) | PVE 9.2.21, kernel pinned to 6.17.13 (7.0 installed, untested). i5-8400 6c · 16 GB · 480 GB SSD |
| Edge VM 100 (192.168.1.34) | 2 GB. nginx + Cloudflare Tunnel + GitHub runner. Serves kotamanish.dev |
| ollama VM 101 (192.168.1.35) | 4 GB · 4 cores (low priority) · GTX 1050 Ti. Models measured, see README |
| Customer network | vmbr1 10.10.0.0/24, isolated (no LAN, no host, no customer-to-customer, no SMTP). Tested |
| Customer tooling | `haki-new <id> <name> <plan>` creates a container; `haki-net` publishes ports to the edge |
| Customers | CT 201 `lalith-bot` (Discord bot) — first pilot customer, running |
| Backups | Plug in USB drive → automatic backup of everything to `Server/proxmox`, keeps 4. Last: 15 Oct |
| Monitoring | `haki-watch` (host, 2 min) + GitHub `watchdog.yml` (external, ~10 min) → Discord channel |
| Security | Key-only SSH on host and edge VM; updates applied 15 Oct; enterprise repos disabled |
| Free capacity | ~8.8 GB RAM on host ≈ 14 more `small` (512 MB) customers |

Access from the PC: `ssh -i ~/.ssh/kmd_admin root@192.168.1.240` (host),
`ssh -i ~/.ssh/kmd_admin root-host@192.168.1.34` (edge VM, sudo needs the user's password).
Proxmox web UI shell/console always works if a key is lost.

## Next steps, in order

1. **Pricing review.** Check `../haki_server/haki_hosting_service_catalogue_and_pricing.md`
   (written before measurements) against real capacity (~14 small plans), real costs
   (electricity ≈ ₹250–350/mo, hardware owned, USB backups), limits (no plans > 1 GB RAM,
   no GPU plans), and competitors. Output: a corrected price list mapped to nano/small/medium.
2. **Haki website.** Finish the existing Vite project in `../haki_server`: corrected plans,
   contact/order form, terms pages. Deploy at a temporary address (e.g. `haki.kotamanish.dev`)
   until hakirun.com is bought, with the same CI/CD as the portfolio. Needs a tunnel hostname
   added on the edge VM (sudo).
3. **Customer self-access.** Cloudflare Access (free ≤ 50 users) for per-customer SSH into their
   own container only. Required before strangers pay.
4. **Payments and legal.** Razorpay/UPI links (user must register), Terms, Acceptable Use Policy,
   Privacy Policy. Prepaid wallet, hourly metering capped at the monthly price.
5. **First paying customer** at a discount for feedback.

## Loose ends

- Old bot copy still on the edge VM (stopped). Remove when convenient — on the edge VM:
  `sudo rm -f /etc/systemd/system/cap-no-cap.service /etc/systemd/system/cap-no-cap.service.pre-tenant.bak && sudo systemctl daemon-reload && sudo rm -rf /srv/tenants /home/root-host/host/others/lalith ~/move-capbot.sh && sudo userdel tn-lalith`
- Bot code updates have no GitHub access from CT 201 yet (do `pct enter 201` for now; solved by step 3 or a deploy key).
- Kernel 7.0 untested — try only with access to the machine's screen (runbook → Updates).
- Single SSD, no redundancy; USB backups are the safety net. Consider a second SSD later.
- RAM upgrade to 32 GB (~₹5–7k) roughly doubles customer capacity — buy after first paying customers.
- `www.kotamanish.dev` DNS records show 525; delete them in Cloudflare. Turn on "Always Use HTTPS"
  and minimum TLS 1.2 in Cloudflare SSL/TLS settings.

## Decisions made (and why)

- **Cloudflare Tunnel, no port forwarding:** home connection is behind CGNAT.
- **Customers in LXC containers on an isolated bridge**, not on the home LAN: their code must never reach personal devices.
- **USB backups on plug-in** rather than a schedule: the drive is portable and not always attached.
- **Custom alert script instead of Uptime Kuma:** Kuma needs an account created by the user; revisit when a public status page is wanted.
- **ollama kept** at 4 GB: measured worst case (one 7B model) needs ~3.2 GB.
