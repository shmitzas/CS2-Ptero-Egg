<h1 align="center">🎮 CS2 Ptero Egg</h1>

<p align="center">
  Counter-Strike 2 server egg for <b>Pterodactyl</b> and <b>Pelican</b>, built on the SteamRT3 platform.
</p>

<p align="center">
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/github/license/shmitzas/CS2-Ptero-Egg?style=flat-square&color=blue&label=License"></a>
  <a href="https://github.com/shmitzas/CS2-Ptero-Egg/stargazers"><img alt="Stars" src="https://img.shields.io/github/stars/shmitzas/CS2-Ptero-Egg?style=flat-square&color=yellow&label=Stars"></a>
  <img alt="Pterodactyl and Pelican supported" src="https://img.shields.io/badge/Pterodactyl%20%7C%20Pelican-Supported-0E4688?style=flat-square">
</p>

<p align="center">
  <a href="#-setup-on-a-fresh-pterodactyl-panel"><b>Setup</b></a> ·
  <a href="#-migrating-from-kitsunelab-cs2-egg"><b>Migrate</b></a> ·
  <a href="docs/configuration/configuration-files.md#startup-variables"><b>Variables</b></a> ·
  <a href="docs/README.md"><b>Docs</b></a>
</p>

---

## ✨ Features

| Feature | What it does |
| --- | --- |
| 🔄 **Auto-updaters** | Four modding frameworks, opt-in, refreshed on every restart |
| 📦 **VPK Sync** | Any number of servers off one ~55 GB game install |
| 🔇 **Console filter** | Drop engine spam with declarative patterns |
| 🧹 **Junk cleaner** | Rule-based removal of demos, logs, backups, crash dumps |
| 🏷️ **Error codes** | Stable `KL-XXX-NN` codes, each with a documented fix |
| ⚙️ **JSON config** | Versioned config files that survive image updates |
| 🐞 **GDB debugging** | Attach IDA to a live server |
| 🔓 **Tokenless** | GSLT optional for LAN and private servers |

## 🧩 Frameworks

| Framework | Runtime | Notes |
| --- | --- | --- |
| [MetaMod:Source](https://github.com/alliedmodders/metamod-source) | native | 2.x (Source 2) branch; required by CounterStrikeSharp |
| [CounterStrikeSharp](https://github.com/roflmuffin/CounterStrikeSharp) | .NET 10 | Enables MetaMod for you |
| [SwiftlyS2](https://github.com/swiftly-solution/swiftlys2) | .NET 10 | MetaMod optional; runs alongside CounterStrikeSharp |
| [ModSharp](https://github.com/Kxnrl/modsharp-public) | .NET 10 | Standalone; conflicts with CSS and SwiftlyS2 |

Each framework toggles independently. **Allow Prerelease Updates** moves CounterStrikeSharp, SwiftlyS2 and ModSharp from stable to beta builds — MetaMod always tracks its CS2 branch.

## 🚀 Setup on a fresh Pterodactyl panel

| Requirement | Details |
| --- | --- |
| 🖥️ **Panel** | Pterodactyl 1.x or Pelican, admin access |
| 💾 **Disk** | ~40 GB per server, or ~3 GB with [VPK Sync](#-vpk-sync) |
| 🌐 **Network** | One allocation, TCP + UDP |

**1. Import the egg**
Admin → Nests → Import Egg → [`pterodactyl/cs2-egg.json`](pterodactyl/cs2-egg.json)

**2. Create the server**
Admin → Servers → **Create New**, then **Create Server** at the bottom

**3. Pick the image**
Under **Docker Configuration**, set **Docker Image** to **CS2 Ptero Egg (GHCR)**

**4. Set variables**
Frameworks, map, slots, GSLT → [full list](docs/configuration/configuration-files.md#startup-variables)

**5. Start**
First boot pulls SteamCMD and ~30 GB of game files. Ready at `Source2Init OK`.

📖 Step-by-step: [installation guide](docs/getting-started/installation.md)

## 🔄 Migrating from KitsuneLab CS2 Egg

Both eggs share the same layout — `game/`, `egg/configs/`, `egg/versions.txt` — so game files, plugins, configs and already-installed frameworks carry over untouched.

> [!IMPORTANT]
> Pterodactyl ties variable **values** to the egg they were set on. Switching eggs drops them back to defaults — **write your current values down before step 3**.

**1. Import the egg**
Admin → Nests → Import Egg → [`pterodactyl/cs2-egg.json`](pterodactyl/cs2-egg.json)

**2. Record** the server's current startup variables

**3. Switch**
Admin → Servers → *server* → Startup → set **Nest** and **Egg** to this one

**4. Re-enter** your variable values

**5. Set the image**
Pick **CS2 Ptero Egg (GHCR)** from the **Image** dropdown

**6. Tick Skip Egg Install Script**, **Save Modifications**, restart

Variable names and defaults match one-for-one; `DAEMON_WAIT_MAX_SECS` is the only addition. A legacy `ADDON_SELECTION` value maps to the boolean toggles automatically.

> [!NOTE]
> Step 6 only avoids a pointless reinstall cycle — the install script is a no-op and deletes nothing either way.

## 📦 VPK Sync

Run many servers off one game install. On the host:

```bash
curl -fsSL https://raw.githubusercontent.com/shmitzas/CS2-Ptero-Egg/main/misc/install-cs2-update.sh -o /tmp/install-cs2-update.sh && sudo bash /tmp/install-cs2-update.sh
```

📖 Details: [docs/features/vpk-sync.md](docs/features/vpk-sync.md)

## 📁 Repository layout

```
docker/               Container source (Dockerfile, entrypoint, scripts, utils)
pterodactyl/          cs2-egg.json — the egg imported into the panel
misc/                 Host-side VPK Sync scripts
docs/                 Feature, configuration and troubleshooting docs
tests/                Offline checks for updater release selection
```

## 📚 Docs

| Guide | Covers |
| --- | --- |
| 🧭 [Installation](docs/getting-started/installation.md) | Import, create, first boot |
| ⚡ [Quick Start](docs/getting-started/quickstart.md) | Condensed panel steps |
| ⬆️ [Updating](docs/getting-started/updating.md) | Egg, image and server updates |
| ⚙️ [Configuration](docs/configuration/configuration-files.md) | Startup variables and JSON configs |
| 🔄 [Auto-updaters](docs/features/auto-updaters.md) | Per-framework behaviour |
| 📦 [VPK Sync](docs/features/vpk-sync.md) | Shared game files |
| 🧹 [Cleanup](docs/features/cleanup.md) | Junk removal rules |
| 🏷️ [Error codes](docs/advanced/error-codes.md) | `KL-XXX-NN` reference |
| 🩺 [Troubleshooting](docs/advanced/troubleshooting.md) | Common failures |

## 🙏 Credits

- [K4ryuu](https://github.com/K4ryuu) — [KitsuneLab CS2-Egg](https://github.com/K4ryuu/CS2-Egg)
- [1zc](https://github.com/1zc) — [CS2-Pterodactyl](https://github.com/1zc/CS2-Pterodactyl)
- [Poggu](https://github.com/Poggicek) — [CleanerCS2](https://github.com/Source2ZE/CleanerCS2)

## 📄 License

GPL-3.0. See [LICENSE](LICENSE).
