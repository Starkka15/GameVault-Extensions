# GameVault Extensions

Optional store extensions for [GameVault](https://github.com/Starkka15/GameVault).
GameVault ships with Epic Games, GOG and Amazon Games built in; everything here is
installed, updated and removed from **About → Extensions** inside GameVault.

| Extension | Store | Notes |
|---|---|---|
| `EA` | EA App, through [Maxima](https://github.com/Starkka15/Maxima) | beta |
| `Itchio` | itch.io: owned games and Collections | API key login |
| `Optima` | Ubisoft, through [Optima](https://github.com/Starkka15/Optima) | beta |
| `RPGMaker` | RPG Maker games from your own folders | native, no Proton |
| `Zoom` | ZOOM Platform | DRM-free; native Linux builds preferred |

Removing an extension keeps its login, library and downloaded games on the
device; installing it again picks up where it left off.

## Layout

```
extensions/<id>/      one folder per extension, exactly as it is installed
docs/                 BUILD-AN-EXTENSION.md, the authoring guide
build.py              packages out/<id>.zip and regenerates index.json
index.json            the catalog GameVault reads (main branch)
```

## Publishing a version

1. Bump `version` in `extensions/<id>/manifest.json`.
2. `python build.py <id>` → `out/<id>.zip`, `index.json` updated.
3. Create the GitHub release `<id>-v<version>` with `out/<id>.zip` attached.
4. Commit `index.json`. Devices offer the update from then on.

GameVault checks each download against the `sha256` in `index.json` and only
accepts release assets from this repository.

## Writing an extension

Start with [docs/BUILD-AN-EXTENSION.md](docs/BUILD-AN-EXTENSION.md); the framework
reference is [EXTENSION-SYSTEM.md](https://github.com/Starkka15/GameVault/blob/main/docs/EXTENSION-SYSTEM.md)
in the GameVault repo. Pull requests adding a store are welcome.

## License

BSD 3-Clause, the same as GameVault. See [LICENSE](LICENSE).
