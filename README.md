# Insection Invasion — gray-box loop skeleton

A runnable Godot 4.7 scaffold for the rent-to-own home-defense roguelite: resource
management + tower/building defense + top-down action. This is the **loop
before the art** — colored rectangles and buttons, real systems underneath.

This project is a Godot port of an earlier Phaser 3 + Vite + TypeScript
prototype (`../insect-defense`). The port kept the same architectural split
that prototype was built around:

- **Content is data.** Enemies, traps, waves, and the economy live as Godot
  `Resource` files (`resources/content/*.tres`), typed by schema classes in
  `resources/defs/`. Add a bug or a trap by adding/editing a `.tres` in the
  Inspector — no script changes needed.
- **Logic is pure.** The rules (economy, wave resolution, loss conditions,
  day/night transitions) are engine-free static functions in `systems/`.
  They take plain state in and return plain results, so they're trivial to
  test, balance, or hand to an AI in isolation.
- **Engine is thin glue.** Scene scripts in `scenes/` just read state, call a
  system, and react to signals. Swap the UI out later and the systems come
  with you unchanged.

See [`structure.md`](structure.md) for the full architecture breakdown,
including a mapping back to the original TypeScript project.

## Running it

Requires [Godot 4.7](https://godotengine.org) (GL Compatibility renderer,
already configured in `project.godot`).

1. Open Godot 4.7 and "Import" this folder (or double-click `project.godot`
   if Godot is already associated with the file type).
2. Press **F5** (or the Play button in the top-right) to run.

No build step, no package manager — GDScript runs directly from source.

## The loop

`morning → afternoon → night → sleep → (next) morning`

- **Morning** (`scenes/morning/`) — rent is charged if due (a miss ends the
  run). Buy traps, deploy them.
- **Afternoon** (`scenes/afternoon/`) — the push-your-luck choice: **DEFEND**
  (traps get a temporary boost, you earn nothing) or **WORK** (earn the
  desk payout, but the wave hits your placed traps alone).
- **Night** (`scenes/night/`) — install overnight auto-earners, then **Sleep**.
  Sleeping saves the game and escalates the invasion (level up, new enemy
  types unlock) for tomorrow.

Three ways to lose, all checked in `systems/loss.gd` + the rent check:
home takeover (integrity 0, the only hard stop), player death (health 0 —
currently unreachable in normal play, see `structure.md`), and failing to
make rent.

## Where things live

Quick map (full detail in `structure.md`):

```
autoload/Game.gd       Global singleton holding the one GameState + GameContent instance
resources/defs/        Resource "schema" classes (enemy/trap/wave/economy shapes)
resources/content/      The actual authored data (.tres instances) — edit in the Inspector
state/                  GameState + small state-shape classes; save/load contract
systems/                Pure, engine-free logic (economy, waves, loss, day_director, ...)
scenes/main/            Main.tscn — persistent root (Hud + swappable phase + GameOverOverlay)
scenes/boot/            One-time redirect to Main on startup
scenes/morning|afternoon|night/   One scene + script per phase
scenes/ui/              Reusable UI: Hud, GameOverOverlay, ShopButtonRow
```

## Extending it (the data-driven payoff)

- **New enemy:** duplicate an existing `.tres` in `resources/content/enemies/`
  (or create a new `EnemyDef` resource) in the editor. Set
  `unlocks_at_invasion_level` to gate when it first appears overnight.
- **New trap:** add a `.tres` to `resources/content/traps/`.
- **New wave:** add a `.tres` to `resources/content/waves/`, keyed by
  `invasion_level`. Levels with no authored wave are auto-scaled from the
  last one (`systems/waves.gd`), so runs never dead-end.
- **Balance:** everything the economy needs is in
  `resources/content/economy/economy_config.tres`.

Because content lives as typed `Resource` classes, most malformed data is
impossible by construction (the Inspector enforces field types). The one
thing that isn't enforced by typing — every wave entry pointing at a real
enemy id — is checked at boot in `systems/content_loader.gd` and fails
loudly (`push_error` + refuses to start) if a wave references an unknown
enemy.

## Next steps toward the real game

1. Replace the abstract `Waves.resolve_wave` with a real-time action layer
   for the DEFEND branch (per-entity movement/combat). Keep auto-resolve for
   the WORK branch — the interface stays the same.
2. Turn trap placement into a real grid/border UI instead of "deploy all."
3. Add the desk-job minigame in place of the flat WORK payout.
4. Either wire an actual damage source for `player_health`, or remove the
   dead `player_death` loss branch if it's not part of the plan.
5. Once real art/audio assets are large enough to need it, turn `Boot` into
   an actual loading screen (progress bar over threaded resource loads)
   instead of the instant pass-through it is today.
