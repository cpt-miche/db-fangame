# DB Fangame - Godot Isometric MVP

This repository now includes a Godot 4.x vertical-slice foundation for a top-down isometric exploration flow with turn-based Dragon Ball-inspired combat.

## Implemented foundation
- Godot project bootstrap (`project.godot`) with main scene wiring.
- Isometric world scene scaffold with:
  - player controller (`WASD` input),
  - enemy NPC interaction (`E` to challenge),
  - world-to-battle transition signal flow.
- Battle scene scaffold with:
  - battle controller,
  - action buttons (`strike`, `ki_blast`, `ki_volley`, `ki_barrage`, `power_up`, `guard`, `transform`),
  - ki infusion slider,
  - log/status labels.
- Data-driven combat definitions via `Resource` files:
  - fighter stats,
  - attack definitions,
  - transformation definition (Kaioken).
- Core combat resolver logic for:
  - escalation hold-back suppression,
  - stamina/drawn-ki mitigation,
  - vanish + potential counter,
  - hit/miss and damage resolution,
  - per-turn Kaioken drain.

## Quick start (Godot)
1. Install Godot 4.x.
2. Open this folder as a Godot project.
3. Run the project (`F5`) to launch `scenes/main/Main.tscn`.

## Exporting executable
In Godot:
1. `Project -> Export`
2. Add preset: **Windows Desktop**
3. Export project to produce self-contained desktop build artifacts.

## Key directories
- `scenes/` scene hierarchy
- `scripts/` gameplay logic (world, battle, core models)
- `resources/` data-driven combat configuration
- `assets/` placeholder art folders and templates
- `docs/` implementation notes

## Working with me via Pull Requests (recommended)
Yes — you can absolutely have me do this as a normal PR workflow.

### How it works
1. You tell me what to change.
2. I edit files, run checks, and commit.
3. I prepare a PR title/body for you.
4. You open/merge it in GitHub.

### Important note about this environment
In this runtime, direct `git push` to GitHub may be blocked by network policy. If that happens:
- I still make the commit locally and provide exact next commands.
- Running the same flow in GitHub Codespaces usually allows push/merge normally.

### Minimum Git commands you may run in Codespaces
```bash
git checkout -b feature/<short-name>
# (I make edits and commit)
git push -u origin feature/<short-name>
```
Then create a PR on GitHub from `feature/<short-name>` into `main`.
