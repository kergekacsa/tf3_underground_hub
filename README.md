# Underground Hub

A private mod for Transport Fever 3. It is not published. The terms are in `CONTEXT.md` and the decisions in `docs/adr/`.

## Origin

The mod starts as a copy of [Underground Railway Station](https://mod.io/g/transportfever3/m/underground-railway-station) (mod A, `mx_underground_railway_station`, revision 7). The features of [Simple Underground Transfer Station](https://mod.io/g/transportfever3/m/simple-metro-transfer-station1) (mod B, `underground_station_transfer_1`, revision 3) are ported in. Both mods belong to their authors. This copy is for private use only.

## Status

The hub builds one to four stacked levels. Each level is a two-track platform with side platforms. All features are built. All features passed the game tests.

| Step | Feature | State |
|---|---|---|
| 1 | Copy of mod A with its own id, path and strings | Done |
| 1b | Layouts 2 to 7 removed (ADR 0001) | Done |
| 2 | One to four levels with own angle and length, 18 m apart, joined to the entrance ring by a shaft | Tested in the game |
| 3 | Rail or tram per level | Tested in the game |
| 4 | Cargo mode for the hub: passenger, cargo or mixed | Tested in the game |
| 5 | Greyed-out controls and a divider between the parameter groups | Tested in the game |
| 6 | Yellow 4 px divider, room around it, sliders one third narrower with the value next to them, one catenary switch and three blocks, taller settings window (`hub_params.css.lua`) | Tested in the game |

## Parameters

| Parameter | Choices | Applies to |
|---|---|---|
| Levels | 1 to 4 | Hub |
| Operation | Passenger, Cargo, Mixed | Hub. Cargo and Mixed add the cargo depot and open the lanes and terminals to cargo. |
| Level n vehicles | Rail, Tram | Level n. Levels 2 to 4 are greyed out below their level count. |
| Level n angle | 0° to 360° in steps of 5° | Level n. The defaults are 0°, 90°, 45° and 135°. |
| Level n length | 40, 80, 120, 160, 240, 320 m | Level n |
| Track bed, track type | As in mod A | Rail levels. Greyed out when no level is rail. |
| Catenary | No, Yes | Rail levels (catenary on the track) and tram levels (electric tram track). |
| Interior style | Original, Japanese | The models of rail levels and the surface building. Tram levels keep the original look. |
| Tunnel connections | Concrete, masonry | Rail levels. Greyed out when no level is rail. |

The game draws a divider between parameter groups: the hub (levels, operation, track bed, track type, catenary), the style (interior style, tunnel connections), and one group per level. The stylesheet `hub_params.css.lua` sets its thickness and colour (yellow, 4 px) and the spacing of the list around it. It also narrows the sliders of the settings window to 187 px, so the right side stays free for the scroll wheel, fixes the slider width so its value box sits next to it, and raises the maximum height of that window (a cap, not a fixed height) to 700 px. It names every group that has a divider above it, so a new group needs an entry in that file. A check function returns "Enabled", "Disabled" or "Hidden". Mod B returns true and false, so its controls never grey out.

## Constraints

- The content path is `content/stations/rail/underground_hub/`. It MUST differ from `stations/rail/underground/` of mod A.
- Mod B writes its files to `stations/street/underground_station/`. That is the path of the underground station that ships with the game, so mod B replaces the game's own station. This mod MUST NOT write to that path.
- The models use the materials of the game station in `stations/street/underground_station/models/mat/`. Those files belong to the game.
- A rail level keeps the geometry of mod A. A tram level uses the geometry of the underground tram station of the game, as mod B does, because a tram needs the lower hall and street edges.
- The loading speed of cargo is the normal speed. Mod B raises it to 200 %; this mod does not.
- The string keys use the prefix `HUB_`, so they do not clash with the `MX_` keys of mod A.

## Tests

The tests run the construction script against stubs of the game modules. They prove the logic, not that the game accepts a call.

```text
cd kacsa_underground_hub
LUA_PATH="tests/?.lua;;" lua55 tests/level_one_test.lua
LUA_PATH="tests/?.lua;;" lua55 tests/hub_test.lua
```

`level_one_test.lua` compares the output of the script for four parameter sets with `tests/golden/level_one.txt`. The golden file records the output of the script before the level builder was extracted. Run it with `--update` only when a change to level 1 is intended.

`hub_test.lua` checks several levels (depth, terminals, node and lane indices, shafts), mixed rail and tram levels, the cargo modes, the greying out of controls, and that the construction file names only existing functions and strings.
