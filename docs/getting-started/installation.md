# Installation Guide

Import the CS2 Ptero Egg into your Pterodactyl panel and boot a server.

## Prerequisites

- Pterodactyl (or Pelican) panel with admin access
- 40 GB+ free disk per node for a fresh CS2 install (or set up [VPK Sync](../features/vpk-sync.md) to share game files)

> [!NOTE]
> The image is published to GHCR as a public package, so nodes pull it with no credentials
> and no `docker login`.

## Step 1: Import the egg

1. Download the raw JSON:
   `https://raw.githubusercontent.com/shmitzas/CS2-Ptero-Egg/main/pterodactyl/cs2-egg.json`
2. Panel → **Admin → Nests** → pick a nest (or create one) → **Import Egg**.
3. Upload the JSON → **Import**.

## Step 2: Create a server (or switch an existing one)

### New server

1. **Admin → Servers → Create New**.
2. Fill basics (name, owner, allocation, resource limits).
3. **Nest Configuration** → nest = whichever you imported into, egg = **CS2 Ptero Egg**.
4. **Docker Configuration** → **Docker Image** → **CS2 Ptero Egg (GHCR)** (the only entry in the list).
5. **Create Server** → the first boot will download SteamCMD + CS2 files (~30 GB, 10-30 min depending on bandwidth).

### Existing CS2 server (switching to this egg)

1. **Admin → Servers →** pick the server → **Startup** tab.
2. Change **Nest** and **Egg** to this egg's entries.
3. **Check** "Skip Egg Install Script" so your existing files aren't wiped.
4. **Image** → **CS2 Ptero Egg (GHCR)**, or paste a tag into *Or enter a custom image…*.
5. **Save Modifications** → restart.

## Step 3: First startup

Watch the console. On a fresh install you'll see:

1. SteamCMD download + install
2. CS2 game files download (~30 GB)
3. Framework installers (only for the ones you enabled in Startup variables)
4. `Source2Init OK` → server is ready

## Docker image details

Only one image is shipped — everything is on GHCR, no Docker Hub, no rate limits, no free-tier surprises.

- **Image**: `ghcr.io/shmitzas/cs2-ptero-egg:latest`
- **Auth**: none — the package is public, so no `docker login` is needed on any node
- **Tags built by CI**: `:latest` (main branch) and `:${sha}` (every commit — pin to one for reproducible restarts)

If a node ever throws `pull access denied` after a redeploy, the auth on that node has expired — re-run `docker login ghcr.io`.

## Next steps

- [Configuration files](../configuration/configuration-files.md) — tune the JSON configs in `/home/container/egg/configs/`
- [VPK Sync](../features/vpk-sync.md) — one game-file install across N servers
- [Auto-Updaters](../features/auto-updaters.md) — enable MetaMod / CSS / SwiftlyS2 / ModSharp per server
- [Troubleshooting](../advanced/troubleshooting.md) if the first boot doesn't reach `Source2Init OK`

## Support

Open an issue at [shmitzas/CS2-Ptero-Egg](https://github.com/shmitzas/CS2-Ptero-Egg/issues).
