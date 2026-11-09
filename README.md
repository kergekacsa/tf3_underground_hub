# Underground Hub

A private mod for Transport Fever 3. It is not published. The terms are in `CONTEXT.md` and the decisions in `docs/adr/`.

## Origin

The mod starts as a copy of [Underground Railway Station](https://mod.io/g/transportfever3/m/underground-railway-station) (mod A, `mx_underground_railway_station`, revision 7). The features of [Simple Underground Transfer Station](https://mod.io/g/transportfever3/m/simple-metro-transfer-station1) (mod B, `underground_station_transfer_1`, revision 3) are ported in. Both mods belong to their authors. This copy is for private use only.

## Status

The folder holds the copy of mod A under the new id `kacsa_underground_hub`. It has no new feature yet.

| Step | Feature | State |
|---|---|---|
| 1 | Copy of mod A with its own id, path and strings | Done |
| 1b | Layouts 2 to 7 removed (ADR 0001) | Done |
| 2 | One to four levels with own angle and length | Open |
| 3 | Rail or Tram per level | Open |
| 4 | Cargo mode for the hub | Open |

## Constraints

- The content path is `content/stations/rail/underground_hub/`. It MUST differ from `stations/rail/underground/` of mod A.
- Mod B writes its files to `stations/street/underground_station/`. That is the path of the underground station that ships with the game, so mod B replaces the game's own station. This mod MUST NOT write to that path.
- The models use the materials of the game station in `stations/street/underground_station/models/mat/`. Those files belong to the game.
- The string keys use the prefix `HUB_`, so they do not clash with the `MX_` keys of mod A.
