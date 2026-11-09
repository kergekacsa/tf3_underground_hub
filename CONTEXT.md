# Underground Hub

A private Transport Fever 3 mod. One underground station that holds one to four stacked levels. Each level is a two-track platform with its own angle, length and vehicle type.

## Language

**Hub**:
The whole station construction that the player places. It holds one to four levels, one cargo mode, and one surface building.
_Avoid_: Station (the game also calls each stop of a line a station)

**Level**:
One underground platform of the hub with two tracks and two side platforms. It has its own depth, angle, length and vehicle type.
_Avoid_: Platform (a platform is the strip of one side of a level), layer, floor

**Level count**:
The number of levels the hub holds: 1 to 4.
_Avoid_: Platform count

**Level angle**:
The compass direction of one level in degrees, in steps of 5. Levels at different angles cross above each other.
_Avoid_: Orientation, rotation

**Level length**:
The platform length of one level: 40, 80, 120, 160, 240 or 320 m.
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

**Source mods**:
The two public mods this mod is built from. Mod A is Underground Railway Station and gives the rail platform and its models. Mod B is Simple Underground Transfer Station and gives the level stacking, the tram lanes and the cargo mode.
_Avoid_: Parent mods, base mods

**Shaft**:
The pedestrian connection between the entrance ring and the passageway of a deeper level. It is a lane only and has no model.
_Avoid_: Lift, escalator, stairwell
