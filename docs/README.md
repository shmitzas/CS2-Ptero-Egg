# CS2 Ptero Egg — Documentation

Setup, configuration and troubleshooting for a Pterodactyl / Pelican Counter-Strike 2 server egg
built on the SteamRT3 platform.

## Getting started

- [Installation](getting-started/installation.md) — import the egg, pick the image, first boot
- [Quick Start](getting-started/quickstart.md) — condensed panel steps
- [Updating](getting-started/updating.md) — egg + image + server updates

## Features

- [VPK Sync & Centralized Updates](features/vpk-sync.md) — one game-file install shared across N servers
- [Auto-Updaters](features/auto-updaters.md) — MetaMod / CSS / SwiftlyS2 / ModSharp
- [Automatic Cleanup](features/cleanup.md) — rule-based removal of demos, logs, backups and dumps
- Console filter — configured via [`console-filter.json`](configuration/configuration-files.md#console-filterjson)

## Configuration

- [Configuration files](configuration/configuration-files.md) — JSON files at `/home/container/egg/configs/`

## Advanced

- [GDB debugging](advanced/debugging.md)
- [Error codes](advanced/error-codes.md) — `KL-XXX-NN` prefix reference
- [Troubleshooting](advanced/troubleshooting.md)

## Downloads

- Egg JSON: [`pterodactyl/cs2-egg.json`](../pterodactyl/cs2-egg.json)
- Image: `ghcr.io/shmitzas/cs2-ptero-egg:latest`

## Changelog

Release history: [CHANGELOG](../CHANGELOG).

## License

GPL-3.0. See [LICENSE](../LICENSE).

## Credits

- [K4ryuu](https://github.com/K4ryuu) — [KitsuneLab CS2-Egg](https://github.com/K4ryuu/CS2-Egg)
- [1zc](https://github.com/1zc) — [CS2-Pterodactyl](https://github.com/1zc/CS2-Pterodactyl)
- [Poggu](https://github.com/Poggicek) — [CleanerCS2](https://github.com/Source2ZE/CleanerCS2)
