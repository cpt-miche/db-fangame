# Art Manifest Template (Vertical Slice)

## Target
- Resolution: `960x360` (prototype), upscale later to 1280x720.
- Format: transparent PNG for sprites/UI, optional sprite sheets.

## Required Sprite Sets

### Player (`assets/sprites/player/`)
- `player_idle.png`
- `player_walk_01.png` to `player_walk_04.png`
- `player_powerup.png`
- `player_strike.png`
- `player_ki_blast.png`
- `player_hurt.png`
- `player_ko.png`
- `player_kaioken.png`

### Enemy (`assets/sprites/enemies/`)
- `raditz_idle.png`
- `raditz_walk_01.png` to `raditz_walk_04.png`
- `raditz_strike.png`
- `raditz_ki_blast.png`
- `raditz_hurt.png`
- `raditz_ko.png`
- `raditz_kaioken.png`

## Backgrounds (`assets/backgrounds/`)
- `world_plains_layer_1.png`
- `world_plains_layer_2.png`
- `battle_backdrop.png`

## UI (`assets/ui/`)
- `bar_hp.png`
- `bar_stamina.png`
- `bar_stored_ki.png`
- `bar_drawn_ki.png`
- `action_button.png`

## VFX (`assets/vfx/`)
- `vanish_puff.png`
- `ki_blast_small.png`
- `ki_blast_volley.png`
- `ki_blast_barrage.png`
- `counter_flash.png`

## Notes
- Keep each character's frame canvas identical size.
- Provide anchor/pivot notes for feet position.
- Preferred naming: `character_action_frame.png`.
