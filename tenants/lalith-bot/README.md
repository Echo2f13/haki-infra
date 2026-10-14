# lalith-bot (CT 201)

Discord bot "Cap No Cap" — first Haki customer. Plan `small`, IP 10.10.0.101, no inbound port.

- Code: `/opt/cap-no-cap` inside the container, owned by system user `bot`.
  Source: `github.com/ilathl/Cap-No-Cap-bot`.
- Secrets: `/opt/cap-no-cap/.env` (Discord token) — only on the container, never in this repo.
- Data: `/opt/cap-no-cap/capbot.db` (SQLite), included in USB backups.
- Service: `cap-no-cap.service` (this folder), runs as `bot` with a read-only system.

```bash
pct exec 201 -- systemctl status cap-no-cap
pct exec 201 -- journalctl -u cap-no-cap -n 50
```
