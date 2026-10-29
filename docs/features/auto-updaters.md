# Auto-Updaters

Automatically update MetaMod, CounterStrikeSharp, SwiftlyS2, and ModSharp on server startup with independent control per framework.

## Overview

The egg includes automatic updaters for popular CS2 server plugins with **multi-framework support** → enable multiple frameworks simultaneously:

- **MetaMod:Source** → Core plugin framework (required for CSS)
- **CounterStrikeSharp (CSS)** → C# plugin framework (.NET 10)
- **SwiftlyS2** → C# framework v2 with .NET 10 runtime (MetaMod optional)
- **ModSharp** → Standalone C# platform with .NET 10 runtime

Updates happen automatically on server startup, keeping your plugins current without manual intervention.

**Version Tracking:** All addon versions are stored in `/home/container/egg/versions.txt`

## Configuration

### Multi-Framework Selection

Each framework has an independent boolean toggle in the Pterodactyl panel:

| Variable             | Description                                      | Auto-Updates |
| -------------------- | ------------------------------------------------ | ------------ |
| `INSTALL_METAMOD`    | MetaMod:Source (required for CSS)                | [✓]           |
| `INSTALL_CSS`        | CounterStrikeSharp (auto-enables MetaMod)        | [✓]           |
| `INSTALL_SWIFTLY`    | SwiftlyS2 (MetaMod optional)                     | [✓]           |
| `INSTALL_MODSHARP`   | ModSharp standalone with .NET 10                 | [✓]           |

**Multi-Framework Examples:**
- MetaMod + CSS + SwiftlyS2 → All three enabled simultaneously [✓]
- MetaMod + ModSharp → Compatible combination [✓]
- CSS only → MetaMod auto-enabled as dependency [✓]
- ModSharp + CSS → Installed anyway, with a conflict warning [!]
- ModSharp + SwiftlyS2 → Installed anyway, with a conflict warning [!]

Only the CSS → MetaMod dependency is enforced. The ModSharp conflicts are advisory: the egg
logs a warning and still installs everything you enabled, so the combination is yours to undo.

### Setting Up

**Via Pterodactyl Panel:**

1. Go to **Startup** tab
2. Toggle checkboxes for desired frameworks:
   - ☑ MetaMod:Source
   - ☑ CounterStrikeSharp
   - ☐ SwiftlyS2
   - ☑ ModSharp
3. Save and restart server

**Via Environment Variables:**

```bash
INSTALL_METAMOD=1
INSTALL_CSS=1
INSTALL_SWIFTLY=0
INSTALL_MODSHARP=1
```

### Dependency Handling

The egg automatically handles dependencies:

```
CSS enabled + MetaMod disabled
       ↓
[WARNING] CounterStrikeSharp requires MetaMod:Source, auto-enabling...
       ↓
Both MetaMod and CSS installed
```

### Load Order Management

**MetaMod always loads first** after Game_LowViolence (critical for proper initialization):

```
Game_LowViolence    csgo_lv
            Game    csgo/addons/metamod        ← Always first
            Game    csgo/addons/counterstrikesharp
            Game    csgo/addons/swiftlys2
            Game    sharp                       ← ModSharp

            Game    csgo
```

## MetaMod:Source

### What It Does

- Downloads the latest MetaMod:Source **2.x** (Source 2) build from GitHub releases
- Extracts to `game/csgo/addons/metamod/`
- Configures `gameinfo.gi` automatically (always first position)
- Stores version in `/home/container/egg/versions.txt`

### How It Works

1. Checks current installed version
2. Fetches releases from `alliedmodders/metamod-source`, restricted to `mmsource-2.*-linux.tar.gz`
3. Compares build numbers (format: `gitNNNN`, read from the asset filename)
4. Downloads and extracts if a newer build is available
5. Updates `gameinfo.gi` to load MetaMod first

AlliedModders flags its 2.x CS2 builds as prereleases and leaves the 1.x Source 1 branch as the
GitHub "latest" release. This updater therefore always reads the prerelease channel and filters
to 2.x assets, ignoring the `PRERELEASE` toggle — a 1.x build cannot load CS2.

### Console Output

```
[CS2] > Checking MetaMod updates...
[CS2] > Update available for Metamod: git1483 (current: git1482)
[CS2] > Metamod updated to git1483
```

## CounterStrikeSharp

### What It Does

- Downloads latest CSS from GitHub releases
- Extracts to `game/csgo/addons/counterstrikesharp/`
- Installs with-runtime version (includes .NET runtime)
- Auto-enables MetaMod if not already enabled
- Stores version in `/home/container/egg/versions.txt`

### Prerequisites

- **MetaMod required** → Automatically enabled when CSS is toggled on

### How It Works

1. Checks if MetaMod enabled (auto-enables with warning if not)
2. Checks current CSS version
3. Fetches latest release from roflmuffin/CounterStrikeSharp
4. Downloads with-runtime Linux build
5. Extracts and updates version tracking

### Console Output

```
[CS2] > [WARNING] CounterStrikeSharp requires MetaMod:Source, auto-enabling...
[CS2] > Checking CSS updates...
[CS2] > CSS is up-to-date (v1.0.378)
```

### Plugin Compatibility

CSS updates may break plugins. Consider:

- Test updates on development server first
- Check plugin compatibility before updating
- Monitor CSS changelog for breaking changes
- Backup before enabling auto-updates

### Multi-Framework Compatibility

CounterStrikeSharp can coexist with:
- [✓] MetaMod (required dependency)
- [✓] SwiftlyS2
- [!] ModSharp (conflict warning only — both are still installed)

## SwiftlyS2

### What It Does

- Downloads latest SwiftlyS2 from GitHub releases
- Extracts to `game/csgo/addons/swiftlys2/`
- Installs with-runtime Linux version
- Configures `gameinfo.gi` automatically
- **MetaMod optional** → loads on its own, and runs just as happily with MetaMod enabled
- Stores version in `/home/container/egg/versions.txt`

### Prerequisites

- **None** → MetaMod is not required, only optional

### How It Works

1. Checks current SwiftlyS2 version
2. Fetches latest from swiftly-solution/swiftlys2
3. Downloads with-runtimes-linux.zip
4. Extracts swiftlys2 directory
5. Updates `gameinfo.gi` to load SwiftlyS2
6. Deletes `addons/metamod/swiftlys2.vdf` if present — this egg always loads SwiftlyS2 from `gameinfo.gi`, never as a MetaMod side-load

### What an update overwrites

| Path | On update |
|------|-----------|
| `bin/`, `gamedata/` | **Replaced** — upstream owns them |
| `configs/**` that you already have | **Kept** — your edits survive |
| `configs/**` that is new this release | **Added** |
| `*.example.*` anywhere | **Replaced** — templates are upstream's |
| `plugins/`, anything else you added | **Untouched** |

Before this, an update copied *only* `bin/` and `gamedata/`, so `configs/` froze
at whatever the first install wrote. A config file added by a later SwiftlyS2
release never appeared on an existing server — `configs/menus/menus.jsonc`, which
controls menu key binds, is the one that surfaced it.

> [!NOTE]
> **Templates are refreshed on purpose.** A `*.example.*` file is upstream's
> documentation of what a config can contain; keeping a stale one is how a server
> owner misses a setting that was added upstream. If you edited an example file in
> place, copy it to the real name instead — that copy is then yours and is kept.

### Console Output

```
[CS2] > Checking SwiftlyS2 updates...
[CS2] > Update available for SwiftlyS2: v1.5.0 (current: v1.4.11)
[CS2] > SwiftlyS2 updated to v1.5.0
```

### Multi-Framework Compatibility

SwiftlyS2 can coexist with:
- [✓] CounterStrikeSharp (CSS)
- [✓] MetaMod
- [!] ModSharp (conflict warning only — both are still installed)

SwiftlyS2 itself also supports side-loading under MetaMod, but this egg does not use that mode:
it registers SwiftlyS2 in `gameinfo.gi` and deletes `addons/metamod/swiftlys2.vdf` on every start.
Enabling MetaMod next to SwiftlyS2 is still fine — the two simply load independently.

## ModSharp

### What It Does

- Downloads latest ModSharp from GitHub releases
- Installs .NET 10 runtime automatically
- Extracts to `game/sharp/`
- Configures `gameinfo.gi` automatically
- **Standalone** → No MetaMod dependency
- Stores versions in `/home/container/egg/versions.txt`

### Prerequisites

- **None** → Completely standalone with bundled .NET 10

### How It Works

1. Checks and installs .NET 10.0.0 runtime if needed
2. Checks current ModSharp version
3. Fetches latest from Kxnrl/modsharp-public
4. Downloads core + extensions assets
5. Extracts preserving existing configs (`core.json` not overwritten)
6. Updates `gameinfo.gi` to load ModSharp

ModSharp's release tags read `git-197` while the assets and the version file use `git197`; the updater
normalises the tag so the two agree.

### Console Output

```
[CS2] > Installing .NET 10.0.0 runtime...
[CS2] > .NET 10.0.0 runtime installed successfully
[CS2] > Checking ModSharp updates...
[CS2] > Update available: git197 (current: git196)
[CS2] > ModSharp updated to git197
```

### Configuration

ModSharp configs are in `game/sharp/configs/core.json`. First install creates default config, updates preserve your settings.

### Multi-Framework Compatibility

ModSharp can coexist with:
- [✓] MetaMod only
- [!] CounterStrikeSharp (CSS) - conflict warning only, both are still installed
- [!] SwiftlyS2 - conflict warning only, both are still installed

**Note:** ModSharp is a standalone framework that conflicts with other C# frameworks. Only MetaMod can run alongside it.

## Version Tracking

### Version File

Versions are stored in `/home/container/egg/versions.txt`:

```
Metamod=git1483
CSS=v1.0.378
Swiftly=v1.5.0
ModSharp=git197
DotNet=10.0.0
```

### Location

- **Path:** `/home/container/egg/versions.txt`
- **Accessible via FTP:** Yes
- **Backed up with server data:** Yes

### Smart Updates

The updater:

- [✓] Only downloads when new version available
- [✓] Compares versions before downloading
- [✓] Skips updates if already current
- [✓] Logs all version changes

This saves bandwidth and startup time.

## Update Schedule

### When Updates Happen

- **On server startup** → Every time container starts
- **Not during runtime** → Server must restart to update
- **After game updates** → Auto-restart triggers update

### Forcing Updates

To force update:

1. Delete version file: `rm /home/container/egg/versions.txt` (via FTP or console)
2. Restart server
3. Will re-download latest versions

### Preventing Updates

To disable updates for specific framework:

1. Toggle off the framework checkbox in Pterodactyl panel
2. Or set environment variable to `0`: `INSTALL_CSS=0`
3. Framework won't be updated or installed

## Combining with Auto-Restart

Auto-Restart + Auto-Updaters = Fully automated server:

```
CS2 Update Detected
       ↓
Server Restarts
       ↓
Game Files Update (SteamCMD)
       ↓
Plugins Update (Auto-Updaters)
       ↓
gameinfo.gi Load Order Verified
       ↓
Server Online with Latest Everything
```

Perfect for hands-off server management!

## Troubleshooting

### MetaMod Not Installing

**Check:**

- github.com and objects.githubusercontent.com accessible
- Sufficient disk space
- Write permissions on `game/csgo/addons/`

**Solution:**

```bash
# Check manually — should list mmsource-2.x Linux assets
curl -s https://api.github.com/repos/alliedmodders/metamod-source/releases \
  | grep -o 'mmsource-2[^"]*linux\.tar\.gz' | head
```

### CSS Not Installing

**Check:**

- MetaMod auto-enabled (check for [WARNING] message)
- GitHub API not rate-limited
- Downloaded correct platform (Linux)
- Sufficient disk space

**Common error:**

```
[ERROR] No suitable asset found for roflmuffin/CounterStrikeSharp
```

**Solution:** GitHub API rate limit → wait 1 hour or check network access

### SwiftlyS2 Not Installing

**Check:**

- GitHub releases accessible
- Correct asset downloaded (with-runtimes-linux.zip)
- No file permission issues

**Note:** SwiftlyS2 does not require MetaMod, and runs fine with it enabled.

### ModSharp Not Installing

**Check:**

- .NET runtime installation succeeded
- GitHub releases accessible
- Both core and extensions assets downloading
- Sufficient disk space for .NET 10 runtime

**Common issue:** .NET runtime download failure → check Microsoft CDN access

### Version Not Updating

**Problem:** Same version reinstalls every startup

**Cause:** Version file not being written/read correctly

**Solution:**

1. Check `/home/container/egg/versions.txt` exists and is readable
2. Verify write permissions on `/home/container/egg/`
3. Check for errors in console during update
4. Delete version file and restart to regenerate

### Load Order Issues

**Problem:** Plugins not loading correctly

**Cause:** Incorrect gameinfo.gi load order

**Solution:** MetaMod must be first addon after LowViolence. The egg handles this automatically via `ensure_metamod_first()` function.

**Verify load order:**

```bash
cat game/csgo/gameinfo.gi | grep -A 10 "Game_LowViolence"
```

Should show:
```
Game_LowViolence    csgo_lv
            Game    csgo/addons/metamod        ← MetaMod FIRST
            Game    csgo/addons/counterstrikesharp
            ...other addons...

            Game    csgo
```

### Rate Limiting

**Error:** `API rate limit exceeded` or `403 Forbidden`

**Cause:** Too many requests to GitHub API

**Solution:**

- Wait 1 hour for rate limit reset
- Less frequent restarts during development
- Check GitHub status: https://www.githubstatus.com/

## Migration from Old System

### Deprecated ADDON_SELECTION Variable

If you're using the old `ADDON_SELECTION` dropdown:

**Warning Message:**
```
[CS2] > [WARNING] DEPRECATION WARNING
[CS2] > [WARNING] The ADDON_SELECTION variable is deprecated and will be removed in the next update!
[CS2] > [WARNING] Please update your Pterodactyl egg to use the new multi-framework support:
[CS2] > [WARNING]   → INSTALL_METAMOD (boolean)
[CS2] > [WARNING]   → INSTALL_CSS (boolean)
[CS2] > [WARNING]   → INSTALL_SWIFTLY (boolean)
[CS2] > [WARNING]   → INSTALL_MODSHARP (boolean)
```

**Migration Steps:**

1. Download latest egg JSON from GitHub
2. Re-import egg in Pterodactyl panel
3. Configure new boolean variables to match your current setup:
   - Old: `ADDON_SELECTION="Metamod + CounterStrikeSharp"`
   - New: `INSTALL_METAMOD=1` + `INSTALL_CSS=1`
4. Restart server
5. Verify frameworks load correctly

**Backwards Compatibility:**

The old `ADDON_SELECTION` variable still works temporarily:

| Old Value                          | New Equivalent                      |
| ---------------------------------- | ----------------------------------- |
| `Metamod Only`                     | `INSTALL_METAMOD=1`                 |
| `Metamod + CounterStrikeSharp`     | `INSTALL_METAMOD=1` + `INSTALL_CSS=1` |
| `SwiftlyS2`                        | `INSTALL_SWIFTLY=1`                 |
| `ModSharp`                         | `INSTALL_MODSHARP=1`                |

This compatibility will be removed in the next major update!

## Best Practices

1. **Test updates** on dev server before production
2. **Backup plugins** before enabling auto-updates
3. **Monitor changelogs** for breaking changes
4. **Use multi-framework wisely** → Test compatibility between frameworks
5. **Keep MetaMod updated** → Required by CSS
6. **Check plugin compatibility** after updates
7. **Use stable releases** in production
8. **Enable only needed frameworks** → Reduces startup time

## FAQ

**Q: Can I use CSS and SwiftlyS2 together?**
A: Yes! They are compatible frameworks and can coexist.

**Q: Can I use CSS and ModSharp together?**
A: Not recommended. The egg logs a conflict warning but installs both, so you can try it — expect conflicts.

**Q: Can I use SwiftlyS2 and ModSharp together?**
A: Not recommended. Same as above: a warning is logged and both are installed anyway.

**Q: What frameworks are compatible with ModSharp?**
A: ModSharp is only compatible with MetaMod. It cannot run alongside CSS or SwiftlyS2.

**Q: Will updates break my plugins?**
A: Possibly. Major updates can have breaking changes. Test on dev server first.

**Q: Can I rollback an update?**
A: Yes, manually install older version and toggle off auto-updates for that framework.

**Q: How do I update only MetaMod, not CSS?**
A: Toggle off CSS checkbox, keep MetaMod enabled.

**Q: Are beta versions supported?**
A: No, only stable releases from official repos.

**Q: What if GitHub is down?**
A: Updates will fail, but server will start anyway. Updates will work on next restart.

**Q: Can I auto-update custom plugins?**
A: Not built-in. You'll need to modify update scripts or manage them manually.

**Q: Where are versions stored?**
A: In `/home/container/egg/versions.txt` (accessible via FTP)

**Q: Does SwiftlyS2 require MetaMod?**
A: No — but it is not incompatible with it either. Enable MetaMod alongside SwiftlyS2 whenever something else needs it, such as CounterStrikeSharp or any MetaMod plugin.

**Q: Can I enable all 4 frameworks simultaneously?**
A: Technically yes — nothing is disabled for you. But ModSharp conflicts with CSS and SwiftlyS2, so the supported maximum is MetaMod + CSS + SwiftlyS2. Adding ModSharp on top only logs a warning.

## Related Documentation

- [VPK Sync & Centralized Updates](vpk-sync.md) → Automatic CS2 updates and server restarts
- [Configuration Files](../configuration/configuration-files.md) → All configuration options
- [Troubleshooting](../advanced/troubleshooting.md) → Diagnosing failed updates

## Support

Having update issues?

- [Report Issue](https://github.com/shmitzas/CS2-Ptero-Egg/issues)
- [Troubleshooting Guide](../advanced/troubleshooting.md)
