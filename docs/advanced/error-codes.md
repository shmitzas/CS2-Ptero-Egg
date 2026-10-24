# Error Codes

> **Can't find your error here, or the fix didn't work?** Open an issue with the `KL-XXX-NN` code, the full log output, your egg version and the Docker image tag.

Every fatal error raised **inside the container** emits a stable `KL-XXX-NN` code. Look it up here to see what it means, how to diagnose it, and how to fix it.

The host-side VPK daemon (`misc/update-cs2-centralized.sh`) writes to the systemd journal and does **not** use these codes; entries below marked *host-side* are matched on their message text instead.

## Index

- [KL-DMN — Daemon / VPK Sync](#kl-dmn--daemon--vpk-sync)
- [KL-STM — SteamCMD](#kl-stm--steamcmd)
- [KL-SRV — Server runtime](#kl-srv--server-runtime)

---

## KL-DMN — Daemon / VPK Sync

### Daemon push never arrived *(host-side, no code)*

**Symptom**: the server pauses on `Waiting for daemon to finish push...`, then runs a full SteamCMD update instead of using the shared game files. With `DAEMON_WAIT_MAX_SECS` at its default this takes ~180 s.

**Meaning**: `entrypoint.sh` wipes `/home/container/egg/.daemon-managed` at boot and the daemon re-touches it at the end of each push, so a missing marker means the push never completed — the daemon died, never saw the container start event, or could not reach it. The egg then falls back to SteamCMD so the server still boots.

**Diagnose (on host)**:
```bash
grep ^SERVER_IMAGE= /usr/local/bin/update-cs2-centralized.sh   # must list this server's image
sudo systemctl status cs2-vpk-daemon
sudo journalctl -u cs2-vpk-daemon -n 100 --no-pager
ls -la /srv/cs2-shared                      # the shared install the daemon pushes from
```

**Fix**:
1. If `SERVER_IMAGE` does not list the image this server runs, the daemon's `docker events --filter image=…` never matches it. Add it and restart — see [VPK Sync troubleshooting](../features/vpk-sync.md#server-stuck-on-waiting-for-daemon-to-finish-push). This is the usual cause after changing a server's image or migrating from another egg.
2. Restart the daemon, **then** the server: `sudo systemctl restart cs2-vpk-daemon`. The daemon reacts only to container start events and never sweeps containers already running, so a server left waiting has missed its push and needs restarting afterwards.
3. If the service is missing, install it:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/shmitzas/CS2-Ptero-Egg/main/misc/install-cs2-update.sh -o /tmp/install-cs2-update.sh
   sudo bash /tmp/install-cs2-update.sh
   ```
4. For `symlink` mode the daemon bind-mounts into the running container with `nsenter`, which needs kernel ≥ 5.2 and `python3` on the host. On an older host switch `VPK_PUSH_METHOD` to `hardlink` or `copy`.
5. On a slow host, raise `DAEMON_WAIT_MAX_SECS` in the server's startup variables.

---

### KL-DMN-05 — Legacy SYNC_LOCATION directory not found

**Symptom**: `[KL-DMN-05] SYNC_LOCATION directory not found: <path>`

**Meaning**: The `SYNC_LOCATION` environment variable is set but points to a path that doesn't exist inside the container. Usually a misconfigured mount.

**Auto-recovery**: Egg skips VPK sync and proceeds to SteamCMD.

**Fix**:
1. If you're using the centralized daemon now, just **remove `SYNC_LOCATION`** from your server startup variables — the daemon marker supersedes it.
2. If you're still on the legacy setup: verify the Pterodactyl/Pelican **Mount** is active and maps host `/srv/cs2-shared` (or your path) into `SYNC_LOCATION` inside the container.

`SYNC_LOCATION` is deprecated and will be removed after **2026-10-01**. Migrate to the centralized daemon.

---

### KL-DMN-06 — Legacy base file sync failed

**Symptom**: `[KL-DMN-06] Failed to sync base files`

**Meaning**: `rsync` from `SYNC_LOCATION` into `/home/container` failed. Usually permission or disk-full.

**Diagnose**:
```bash
df -h /home/container
ls -la "$SYNC_LOCATION"
```

**Fix**:
1. Free disk space.
2. Check file ownership on the host — the Pterodactyl user must be able to read `SYNC_LOCATION`.
3. Migrate to the centralized daemon (same rationale as [KL-DMN-05](#kl-dmn-05--legacy-sync_location-directory-not-found)).

---

## KL-STM — SteamCMD

### KL-STM-01 — SteamCMD exit code 8

**Symptom**: `[KL-STM-01] SteamCMD connection error (exit code 8)`

**Meaning**: SteamCMD failed with exit 8. The name "connection error" is misleading — in practice this is almost always **disk space / filesystem** failure that cascades into a login/state failure.

**Most common cause — not enough disk space.**

**Diagnose**:
1. `df -h /home/container` — CS2 needs ~60 GB free (3 GB with VPK-sync daemon).
2. Look at the SteamCMD output ABOVE the code line for `state is 0x...`:
   - `state is 0x202` → disk or filesystem issue → see [State 0x202](#state-0x202-disk-space--filesystem-host-side)
   - `Please use force_install_dir before logon!` → egg arg order bug
3. Only if disk is fine: check Steam status at [steamstat.us](https://steamstat.us/) and try `curl -sI https://steamcdn-a.akamaihd.net/`.

**Fix**:
1. Free disk space on the host's panel volume directory.
2. Ensure quota isn't capped (Pterodactyl/Pelican server disk limit).
3. Retry — transient CDN issues self-resolve.
4. If persistent: collect the full SteamCMD output together with the `state is 0x...` code when opening an issue.

---

### KL-STM-02 — SteamCMD generic failure

**Symptom**: `[KL-STM-02] SteamCMD failed with exit code <N>`

**Meaning**: SteamCMD exited non-zero, but not with the well-known code 8. Common values: `7` (no subscription / appid access), `1` (generic), `42` (steamcmd bug).

**Fix**:
1. Check the SteamCMD output just above this line for the actual cause.
2. `SRCDS_APPID=730` for CS2. Verify it isn't overridden.
3. The egg logs in anonymously unless `SRCDS_LOGIN` / `SRCDS_LOGIN_PASS` are present in the container environment. They are not exposed as egg variables, so an admin has to add them to the egg by hand — if you did, verify the credentials.

---

### State 0x202 (disk space / filesystem) *(host-side)*

**Symptom**: `SteamCMD Error 0x202 - Disk space or filesystem issue` in the daemon's journal.

**Meaning**: SteamCMD ran out of disk or hit a filesystem permission / readonly issue while updating the shared install.

**Fix**:
1. `df -h /srv/cs2-shared` — CS2 needs **~60 GB** for a fresh install.
2. Check that the mount isn't read-only: `mount | grep cs2-shared`.
3. Clear incomplete downloads: `rm -rf /srv/cs2-shared/steamapps/downloading` then re-run.

---

### Other SteamCMD state codes *(host-side)*

**Symptom**: `SteamCMD Error 0x<hex> detected` in the daemon's journal.

**Meaning**: SteamCMD returned an unmapped state code. Most codes indicate validation or network failures.

**Fix**: Check the SteamCMD output above the line for the real cause, then re-run the daemon with `--validate` (or set `VALIDATE_INSTALL="true"` in `/usr/local/bin/update-cs2-centralized.sh`).

---

### KL-STM-05 — SteamCMD download failed (container-side)

**Symptom**: `[KL-STM-05] Failed to download SteamCMD after N attempts`

**Meaning**: The egg couldn't fetch the SteamCMD installer from `steamcdn-a.akamaihd.net`. Usually network policy or DNS.

**Fix**:
1. Verify outbound HTTPS works inside the container: `curl -sI https://steamcdn-a.akamaihd.net/`
2. Check your node's firewall / egress rules.
3. Retry — transient CDN failures resolve quickly.

---

### KL-STM-06 — SteamCMD extract failed

**Symptom**: `[KL-STM-06] Failed to extract SteamCMD`

**Meaning**: The downloaded tarball was corrupted or `tar` failed.

**Fix**:
1. Remove the partial archive: `rm -rf /home/container/steamcmd`
2. Re-run — the egg will re-download on next boot.
3. If persistent: check for disk-full (`df -h`).

---

### KL-STM-07 — SteamCMD directory missing

**Symptom**: `[KL-STM-07] steamcmd directory does not exist`

**Meaning**: After extract, `/home/container/steamcmd` wasn't created. The archive was likely malformed or another process deleted it mid-install.

**Fix**: Force-reinstall — delete `/home/container/steamcmd` and restart. If it keeps failing, check for hostile cleanup scripts or antivirus interfering with container volumes.

---

## KL-SRV — Server runtime

### KL-SRV-02 — Steam GSLT token invalid or expired

**Symptom**: `[KL-SRV-02] Steam GSLT token invalid or expired` (preceded by `Cert request for invalid failed with reason code 5005` or `We're not logged into Steam`)

**Meaning**: Steam rejected the Game Server Login Token (`STEAM_ACC`) at connect time. Common causes: token expired from inactivity, revoked by Steam, or registered against the wrong App ID.

**Auto-recovery**: None — the server runs unranked (no public listing, Steam masterserver not reachable) until a valid token is set.

**Diagnose**:
1. Open [Steam Game Server Account Management](https://steamcommunity.com/dev/managegameservers) while logged into the Steam account that owns the token.
2. Find the token value from `STEAM_ACC` in the list. Check "Last Logon" and "Memo" columns.
3. If missing, expired, or revoked → generate a new one.

**Fix**:
1. Create a new token at https://steamcommunity.com/dev/managegameservers with App ID **730** (CS2).
2. In Pterodactyl/Pelican panel → Startup → update `STEAM_ACC` with the new token.
3. Restart the server.

**Alternative** (temporary, rarely needed): set `ALLOW_TOKENLESS=1` in startup variables and restart — the server launches without a token but is unranked and not publicly listed. Use only while you generate a fresh token.

---

### KL-SRV-01 — Server crashed

**Symptom**: `[KL-SRV-01] Server crash detected` (follows `./game/cs2.sh: ... Aborted (core dumped)`)

**Meaning**: CS2 process died unexpectedly. Root cause is in the log lines **above** this error — stack traces, SIG reasons, or plugin error messages.

**Common causes**:

1. **Plugin issues** — recently installed/updated plugin incompatible with the current CS2 version. Disable plugins one at a time to isolate.
2. **Addon compatibility** — MetaMod / CounterStrikeSharp / SwiftlyS2 / ModSharp out of date. Update all via the egg's auto-updater (`Update on Start` = `true` in panel). Verify `gameinfo.gi` load order — MetaMod MUST load first.
3. **Outdated gamedata** — plugin gamedata (offsets, signatures) broken after a CS2 update. Check: https://gdc.eternar.dev

**Fix**:
1. Read the stack trace above the crash marker — it identifies the failing module.
2. Update all addons to latest.
3. If crash is reproducible with minimal plugin set, escalate internally with the core dump info and full log.

---

## Still need help?

If the fix above didn't resolve your issue:

1. **Check [troubleshooting.md](troubleshooting.md)** and [debugging.md](debugging.md) for context.
2. Escalate internally with:
   - The `KL-XXX-NN` error code
   - Full log output (container console + `/home/container/egg/logs/*.log` if file logging is on)
   - Egg version (check `pterodactyl/cs2-egg.json` → `meta.version`)
   - Docker image tag (`ghcr.io/shmitzas/cs2-ptero-egg:latest` or a pinned `${sha}`)
   - If the issue relates to the centralized VPK daemon, ask your node admin for `systemctl status cs2-vpk-daemon` output
