# Underground Hub

A private mod for Transport Fever 3. It is not published. The terms are in `CONTEXT.md` and the decisions in `docs/adr/`.

## Overview

The hub builds one to four stacked underground levels. Each level is a two-track platform with side platforms.

## Origin

The mod follows [Simple Underground Transfer Station](https://mod.io/g/transportfever3/m/simple-metro-transfer-station1) (`underground_station_transfer_1`, revision 3, called the source mod below): the design of every level, the strips on the platforms, the cargo depot and the reconfiguration after construction come from it. The source mod belongs to its author. This copy is for private use only.

## Parameters

Every parameter can change after construction.

| Parameter | Choices | Applies to |
|---|---|---|
| Level n vehicle | Level 1: Rail, Tram. Levels 2 to 4: Off, Rail, Tram | One selector for each level. Off removes the level. Level 1 always exists. A level keeps its depth by its number, so level 3 can exist without level 2. The selector of a connected level is hidden, so that no level with tracks can be removed. |
| Operation | Passenger, Cargo, Mixed | Hub. Cargo and Mixed add the cargo depot and open the lanes and terminals to cargo. |
| Track type | Simple and Standard until 1980, Simple, Standard and High-Speed from 1980 | Rail levels. Greyed out when no level is rail, and locked while a rail level has connected tracks. |
| Catenary | No, Yes | Rail levels (catenary on the track) and tram levels (electric tram track). Locked while any level has connected tracks. |
| Level n angle | 0° to 360° in steps of 5° | Level n. The defaults are 0°, 90°, 45° and 135°. |
| Level n length | 40, 80, 120, 160, 240, 320 m | Level n. A level has two length selectors with the same label: one for rail with the default 240 m, one for tram with the default 40 m. Only the selector of the chosen vehicle shows, and each keeps its own value. |

The game draws a divider between parameter groups: the hub (operation, track type, catenary), and for each level a title, its controls, and a note when it is locked. The dividers above the controls of a level are hidden. The stylesheet `hub_params.css.lua` sets its thickness and colour (yellow, 4 px), the spacing of the list around it, the bold title of a level, and the lock note as red text without a button background. It also narrows the sliders of the settings window to 187 px, so the right side stays free for the scroll wheel, fixes the slider width so its value box sits next to it, and raises the maximum height of that window (a cap, not a fixed height) to 700 px. It names every group that has a divider above it, so a new group needs an entry in that file. A check function returns "Enabled", "Disabled" or "Hidden". The source mod returns true and false, so its controls never grey out.

## Constraints

- The content path is `content/stations/rail/underground_hub/`. It cannot clash with another mod that uses `stations/rail/underground/`.
- The source mod writes its files to `stations/street/underground_station/`. That is the path of the underground station that ships with the game, so it replaces the game's own station. This mod MUST NOT write to that path.
- The hall, stairs and surface building are models of the game station in `stations/street/underground_station/`. Those files belong to the game. This mod ships only the strips (`models/shared/`) and the cargo depot (`models/cargo/`) of the source mod, and the empty model that hides the catenary poles inside a hall.
- A rail level runs its tracks on the floor of the tram hall. The hall model has tram rails baked into its floor, at the same place as the two tracks. The tracks sit 0.3 m below the floor, so that their rails show about 0.24 m above the floor and 0.11 m below the platform edge. A track at floor level hid its rails in the baked tram rails, and a track at -18.0 stood above the platform edge. The two tracks are real railway edges inside a tunnel type without walls, `station_hall.tunnel`. The rail tunnel that joins a hall has a different profile from the hall end. If the join looks wrong in the game, the fix is a transition model.
- A tram level has two parallel inert railway edges across its hall, in a track style whose models are all empty, with nodes that are not free. They exist only so that the placement preview draws the length of the hall, as it does for a rail level. Vehicles do not use them.
- The tunnel that joins a rail level to the world is the newest rail tunnel of the game that is available in the year of the station: the rock tunnel before 1970, the concrete tunnel from 1970. The third rail tunnel of the game is hidden by the game.
- The track type has two selectors with the same key, one for each year range, as in the source mod. The panel of a built station ignores the years, so the check function of each selector hides it outside its years.
- The panel of a built station honours only "Hidden" from a check function, not "Disabled". So there a control that is off, such as the controls of a level that is off or of a connected level, and the vehicle selector of a connected level, is hidden, and the red note stays. The panel of a placed station greys the control out.
- A level counts as connected when a track or street that is not part of the station ends on a free node of that level. The game passes no entity to a check function, so the script finds the edited station by comparing the values of the panel with the stored parameters of every station of this mod (ADR 0003). The hidden parameter `hubPlacement` tells a station that is being placed from a built station that is being edited. The nodes of the station come from its edges, because the free nodes at the ends of its tunnels are not frozen nodes. When the panel changes a value, the values match no station any more, and the script keeps using the stations of the last match, so the lock stays while the panel is open. The result is cached for one second. The log line "[hub] lock lookup" shows how many stations and nodes the lookup examined.
- The dummy slot `underground_dummy` makes the game show the configuration wrench. Reconfiguring a built station rebuilds its edges. The game decides what happens to tunnels that connect to an edge that moves or disappears.
- The loading speed of cargo is the normal speed. The source mod raises it to 200 %; this mod does not.
- The string keys use the prefix `HUB_`, so they do not clash with the keys of other mods.

## Tests

The tests run the construction script against stubs of the game modules. They prove the logic, not that the game accepts a call.

```text
cd kacsa_underground_hub
LUA_PATH="tests/?.lua;;" lua55 tests/hub_test.lua
```

`hub_test.lua` checks several levels (depth, terminals, node and lane indices, shafts), mixed rail and tram levels, the one design of all levels, the platform strips, the cargo modes, the dummy slot, the greying out of controls, that every parameter can change after construction, and that the construction file names only existing functions, models and strings.
