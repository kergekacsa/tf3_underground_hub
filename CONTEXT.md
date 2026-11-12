# Underground Transfer Hub

A Transport Fever 3 mod. One underground station that holds one to four stacked levels. Each level is a two-track platform with its own angle, length and vehicle type.

## Language

**Hub**:
The whole station construction that the player places. It holds up to four levels, one cargo mode, and one surface building.
_Avoid_: Station (the game also calls each stop of a line a station)

**Level**:
One underground platform of the hub with two tracks and two side platforms. It has its own depth, angle, length and vehicle type.
_Avoid_: Platform (a platform is the strip of one side of a level), layer, floor

**Level vehicle**:
The one selector of a level. Level 1 chooses Rail or Tram. Levels 2 to 4 choose Off, Rail or Tram, and Off removes the level. A level keeps its depth by its number, so level 3 can exist without level 2.
_Avoid_: Level switch, level count, platform count

**Level angle**:
The compass direction of one level in degrees, in steps of 5. Levels at different angles cross above each other.
_Avoid_: Orientation, rotation

**Level length**:
The platform length of one level: 40, 80, 120, 160, 240 or 320 m. A new rail level starts at 240 m and a new tram level at 40 m.
_Avoid_: Size

**Vehicle type**:
The choice of one level between Rail and Tram. Rail serves trains and light rail on rail track. Tram serves trams and light rail on tram track.
_Avoid_: Mode (the game calls a vehicle category a transport mode), track type (that is the quality of a rail track)

**Cargo mode**:
The choice of the whole hub between Passenger, Cargo and Mixed. It sets which cargo every level may load.
_Avoid_: Station mode, hybrid

**Level spacing**:
The fixed vertical distance of 18 m between two levels.
_Avoid_: Layer spacing

**Source mod**:
The public mod this mod is built from: Simple Underground Transfer Station. It gives the design, the level stacking, the tram lanes, the cargo mode and the reconfiguration after construction.
_Avoid_: Parent mod, base mod

**Level stairs**:
The pedestrian connection from a level to the ring of the level directly below it. It starts in the four corridors of the upper level, beside the foot of the stairs from the ring, and ends on the ring of the lower level. It has a model.
_Avoid_: Connector, escalator

**Shared platform**:
The round platform in the middle of the lower ring, where the level stairs of both platform sides meet.
_Avoid_: Central landing, podium

**Exit stairs**:
The two stairs from the shared platform down to the ring of the lower level.
_Avoid_: Ring stairs

**Shaft**:
The pedestrian connection between the entrance ring and the passageway of a level that lies below a gap, such as level 3 without level 2. It is a lane only and has no model.
_Avoid_: Lift, escalator, stairwell

**Connected level**:
A level of a built station that has a track or street, not part of the station, on one of its free nodes. While the station is edited, the controls of a connected level are locked and a red note says why.
_Avoid_: Used level, occupied level
