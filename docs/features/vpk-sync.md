# VPK Sync Feature

Dramatically reduce storage and bandwidth by centralizing CS2 game files across all servers on a node.

## Overview

One CS2 install on the node, shared by every server on it. A cron job keeps it updated and pushes the files into each server's volume; a daemon does the same for new servers the moment they start.

> **No panel modifications.** Works directly with Docker and Wings — no patches, no mounts, no extra egg variables.

**First boot:** ~5 seconds, instead of a 10-30 minute SteamCMD download.

| Servers | Without sync | With sync | Saved |
| ------- | ------------ | --------- | ----- |
| 5       | 275GB        | 70GB      | 75%   |
| 10      | 550GB        | 85GB      | 85%   |
| 50      | 2.75TB       | 205GB     | 87%   |

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

It prompts for configuration, installs the update script to `/usr/local/bin/update-cs2-centralized.sh`, starts the `cs2-vpk-daemon` service, and registers a cron job.

Settings live at the top of the installed script:

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

`symlink` suits almost everyone — `CS2_DIR` is bind-mounted read-only into each container so the links resolve. Use `copy` only if servers need to write to game files.

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

## Self-Update

On by default — the script updates itself from GitHub, preserving your config and keeping the last 3 backups. Disable with `AUTO_UPDATE_SCRIPT="false"`.

## Troubleshooting

> The script automatically handles: SteamCMD installation, 32-bit library setup, permissions, Steam SDK libraries, and directory creation.

> **Something broken?** Re-run the installer - it resets config to working defaults while offering your current values as starting points:
>
> ```bash
> curl -fsSL https://raw.githubusercontent.com/shmitzas/CS2-Ptero-Egg/main/misc/install-cs2-update.sh -o /tmp/install-cs2-update.sh && sudo bash /tmp/install-cs2-update.sh
> ```

### Server stuck on "Waiting for daemon to finish push..."

The daemon isn't pushing to this server, so it gives up and downloads its own copy of the game.

Normal right after moving a server to a different egg or image — the daemon doesn't know about it yet. Re-run the installer, then restart the server:

```bash
curl -fsSL https://raw.githubusercontent.com/shmitzas/CS2-Ptero-Egg/main/misc/install-cs2-update.sh -o /tmp/install-cs2-update.sh && sudo bash /tmp/install-cs2-update.sh
```

> [!NOTE]
> Still migrating other servers? The installer points the daemon at this egg's image only. Add it alongside the old one instead:
>
> ```bash
> sudo sed -i 's|^SERVER_IMAGE="|SERVER_IMAGE="ghcr.io/shmitzas/cs2-ptero-egg |' /usr/local/bin/update-cs2-centralized.sh
> sudo systemctl restart cs2-vpk-daemon
> ```

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

**What if the cron job fails?**
Servers keep using the files they have, and the daemon still handles new ones. Push manually with `/usr/local/bin/update-cs2-centralized.sh --simulate`.

**Cron job vs daemon?**
Cron updates CS2 and pushes to existing servers. The daemon reacts to new servers starting, so files are in place before the startup script runs.

**Can I run it without the daemon?**
Yes — new servers then get their files on the next cron cycle (~2 minutes). For most setups this is fine since CS2 startup takes longer than that anyway.

## Support

- [Report Issue](https://github.com/shmitzas/CS2-Ptero-Egg/issues)
- [View Update Script](https://github.com/shmitzas/CS2-Ptero-Egg/blob/main/misc/update-cs2-centralized.sh)
- [View Installer](https://github.com/shmitzas/CS2-Ptero-Egg/blob/main/misc/install-cs2-update.sh)
