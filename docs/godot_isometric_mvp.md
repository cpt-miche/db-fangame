# Godot Isometric MVP Notes

## Tile and map targets
- Perspective: top-down isometric (SNES-style JRPG feel)
- Suggested tile size: `64x32` diamond
- Initial map size: `40 x 40`

## Layer conventions
1. `TileMapLayer_Ground`: walkable base terrain
2. `TileMapLayer_Props`: visual dressing
3. `TileMapLayer_Blockers`: collision blockers

## Encounter loop
1. Move in world scene
2. Enter enemy interaction range
3. Press `E`
4. Transition to battle scene
5. Resolve turn-based combat
6. Return to world

## Battle parity goals vs prototype
- Keep parity with the previous web MVP mechanics while changing presentation.
- Current scripts preserve:
  - resource pooling (HP/stamina/stored ki/drawn ki)
  - escalation suppression
  - ki infusion
  - vanish/counter
  - Kaioken upkeep drain
