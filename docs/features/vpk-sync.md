# VPK Sync Feature

Dramatically reduce storage and bandwidth by centralizing CS2 game files across all servers on a node.

## Overview

VPK Sync allows multiple CS2 servers to share game files from a single centralized location instead of each server maintaining its own complete copy.

**How It Works:**

1. A cron job keeps one centralized CS2 installation updated via SteamCMD
2. After each update, the script pushes game files directly into each server's volume - no Pterodactyl/Pelican mounts or manual configuration required
3. VPK files are shared via symlinks (default), hardlinks, or full copies depending on your `VPK_PUSH_METHOD` setting
4. A daemon watches for new containers and pushes files instantly on first start

> **No Pterodactyl/Pelican Panel modifications required.** The script works directly with Docker and Wings - no PR patches, no mount setup, no egg variable configuration.

## Startup Performance

With the centralized script and VPK sync, new server startup is near-instant:

| Step                                    | Time           |
| --------------------------------------- | -------------- |
| Daemon detects container start          | ~0s            |
| Daemon mounts CS2_DIR into container    | 1-3s           |
| Entrypoint detects VPKs, skips SteamCMD | ~0s            |
| CS2 server process starts               | ~2s            |
| **Total (new server, first boot)**      | **~5 seconds** |

This replaces what would otherwise be a 10-30 minute SteamCMD download on first boot.

## Storage Savings

| Servers | Without Sync | With Sync | Savings      |
| ------- | ------------ | --------- | ------------ |
| 1       | 55GB         | 55GB      | 0GB (0%)     |
| 5       | 275GB        | 70GB      | 205GB (75%)  |
| 10      | 550GB        | 85GB      | 465GB (85%)  |
| 20      | 1.1TB        | 115GB     | 1025GB (86%) |
| 50      | 2.75TB       | 205GB     | 2.6TB (87%)  |

## Prerequisites

- Root access to the node
- Docker (standard on Pterodactyl/Pelican nodes)
- `rsync` - `apt-get install -y rsync`
- ~56GB free storage for one complete CS2 installation
- For `hardlink` mode: `CS2_DIR` and panel volumes must be on the same filesystem

## Installation

Run the installer as root - it handles everything:

```bash
curl -fsSL https://raw.githubusercontent.com/shmitzas/CS2-Ptero-Egg/main/misc/install-cs2-update.sh -o /tmp/install-cs2-update.sh && sudo bash /tmp/install-cs2-update.sh
```

The installer will:

1. Walk you through configuration (paths, push method, restart behavior)
2. Download the update script to `/usr/local/bin/update-cs2-centralized.sh`
3. Install and start the VPK push daemon as a systemd service
4. Register a cron job that runs every minute (rate-limited by `UPDATE_CHECK_INTERVAL`)

After installation, edit the config section at the top of the script to adjust any settings:

```bash
nano /usr/local/bin/update-cs2-centralized.sh
```

## Push Methods

| Method     | Panel disk usage | Writable       | Requirements                                |
| ---------- | ---------------- | -------------- | ------------------------------------------- |
| `symlink`  | ~0 per server    | No (read-only) | None - CS2_DIR auto-mounted into containers |
| `hardlink` | ~53GB per server | No (read-only) | Same filesystem as CS2_DIR                  |
| `copy`     | ~52GB per server | Yes            | None                                        |
| `off`      | -                | -              | -                                           |

**Symlink** (default) - symlinks from each server's volume to CS2_DIR. Panel sees near-zero disk usage. CS2_DIR is automatically bind-mounted read-only into each container so symlinks resolve correctly inside.

**Hardlink** - no extra physical disk space, but panel disk quota counts the full VPK size (~53GB) per server. Requires CS2_DIR on the same filesystem as panel volumes.

**Copy** - each server gets its own independent copy. Useful if servers need write access to game files.

## Quick Reference

```bash
# Run update manually
# If cron is currently running you'll get a lock error - wait a moment and retry
/usr/local/bin/update-cs2-centralized.sh

# Test push and restart logic (skip SteamCMD download)
/usr/local/bin/update-cs2-centralized.sh --simulate

# Daemon status
systemctl status cs2-vpk-daemon

# Daemon logs (live)
journalctl -u cs2-vpk-daemon -f

# Update logs
tail -f /var/log/cs2-update.log
```

## Maintenance

### Script Self-Update

Enabled by default. The script checks GitHub for newer versions, preserves your configuration, validates syntax, and atomically replaces itself. Keeps last 3 backups in `.script-backups/`. Disable with `AUTO_UPDATE_SCRIPT="false"`.

### Monitoring

```bash
tail -f /var/log/cs2-update.log
journalctl -u cs2-vpk-daemon --since "1 hour ago"
```

## Troubleshooting

> The script automatically handles: SteamCMD installation, 32-bit library setup, permissions, Steam SDK libraries, and directory creation.

> **Something broken?** Re-run the installer - it resets config to working defaults while offering your current values as starting points:
>
> ```bash
> curl -fsSL https://raw.githubusercontent.com/shmitzas/CS2-Ptero-Egg/main/misc/install-cs2-update.sh -o /tmp/install-cs2-update.sh && sudo bash /tmp/install-cs2-update.sh
> ```

### Server stuck on "Waiting for daemon to finish push..."

**Symptom:** a server sits on that line for ~3 minutes, then downloads its own ~30 GB copy of the game instead of using the shared install.

**Cause:** the daemon picks containers by image name. `SERVER_IMAGE` in `/usr/local/bin/update-cs2-centralized.sh` becomes `docker events --filter image=…`, so a container running any other image never raises an event the daemon listens for — it is never pushed to, and `/home/container/egg/.daemon-managed` is never created. The container waits out `DAEMON_WAIT_MAX_SECS` (180 s) and falls back to SteamCMD.

This bites anyone who changes a server's Docker image, including migrating from another egg — upstream's installer ships `SERVER_IMAGE="sples1/k4ryuu-cs2 ghcr.io/k4ryuu/cs2-egg"`.

**Fix** — re-run the installer. It replaces the script with this repo's copy, whose default already targets the right image, and repoints self-updates at this repo:

```bash
curl -fsSL https://raw.githubusercontent.com/shmitzas/CS2-Ptero-Egg/main/misc/install-cs2-update.sh -o /tmp/install-cs2-update.sh && sudo bash /tmp/install-cs2-update.sh
```

During a staged migration, where old and new servers run side by side, add this image to the existing list instead. Prepending keeps whatever is already configured — upstream ships two images, and yours may be customised further:

```bash
grep ^SERVER_IMAGE= /usr/local/bin/update-cs2-centralized.sh    # note the current value
sudo sed -i 's|^SERVER_IMAGE="|SERVER_IMAGE="ghcr.io/shmitzas/cs2-ptero-egg |' /usr/local/bin/update-cs2-centralized.sh
grep ^SERVER_IMAGE= /usr/local/bin/update-cs2-centralized.sh    # confirm, and that it ran only once
sudo systemctl restart cs2-vpk-daemon
journalctl -u cs2-vpk-daemon -n 20                              # the "Images:" line lists them all
```

Images are space- or comma-separated. The two update paths treat this key differently: a **self-update** preserves it, so a hand-edit survives; an **installer re-run** does not patch it, so it reverts to this repo's default alone. Neither will correct a stale value you set yourself.

> [!IMPORTANT]
> **Restart the daemon before the servers, in that order.** The daemon reads `SERVER_IMAGE` once at
> startup, so an edited file changes nothing until the service restarts — and it only ever reacts to
> container `create` / `start` / `restart` events, never sweeping containers that are already up. A
> server left waiting while you restart the daemon has already missed its event and will sit there
> until the timeout. Restart it afterwards and the push lands immediately.

> [!NOTE]
> Keeping a daemon installed from another egg works today — it still writes the `egg/.daemon-managed` marker this egg waits on — but upstream has marked that marker legacy and layered a newer `egg/.daemon-status` handshake over it. Install this repo's daemon so the two halves stay on one protocol.

### Cross-Filesystem Hardlink Error

**Error:** `Cross-filesystem hardlink not possible for ptero-xxxx`

`CS2_DIR` and panel volumes are on different partitions.

```bash
# Check filesystems
df -h /srv/cs2-shared
df -h /var/lib/pterodactyl/volumes
df -h /var/lib/pelican/volumes

# Option A: move CS2_DIR onto the same partition as volumes
# Option B: switch to copy mode - edit VPK_PUSH_METHOD="copy" in the script
```

### Cron Job Not Running

```bash
systemctl status cron
cat /etc/cron.d/cs2-update
/usr/local/bin/update-cs2-centralized.sh  # test manually
```

## FAQ

**Q: Do I need to modify Pterodactyl/Pelican Panel or apply any patches?**
No. The script works directly with Docker and Wings.

**Q: Do I need to configure anything on individual servers?**
No. Files are pushed directly into each server's volume from the host.

**Q: What if the cron job fails?**
Servers continue using existing files. The daemon still handles new containers. Run manually to trigger a push: `/usr/local/bin/update-cs2-centralized.sh --simulate`.

**Q: What's the difference between the cron job and the daemon?**
The cron job handles CS2 updates and pushes to all existing servers. The daemon handles new servers - it reacts instantly when a container starts so game files are present before the startup script runs.

**Q: Can I use VPK sync without the daemon?**
Yes. Without the daemon, new servers receive files on the next cron cycle (~2 minutes). For most setups this is fine since CS2 startup takes longer than that anyway.

## Support

- [Report Issue](https://github.com/shmitzas/CS2-Ptero-Egg/issues)
- [View Update Script](https://github.com/shmitzas/CS2-Ptero-Egg/blob/main/misc/update-cs2-centralized.sh)
- [View Installer](https://github.com/shmitzas/CS2-Ptero-Egg/blob/main/misc/install-cs2-update.sh)
