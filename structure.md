# Project structure

This is a Godot 4.7 / GDScript port of a Phaser 3 + Vite + TypeScript
prototype (`../insect-defense`). This doc explains how the current project
is put together, why it's shaped the way it is, and how it maps back to the
original.

## Folder layout

```
project.godot                          Autoload registration + main scene + renderer settings

autoload/
  Game.gd                              Autoload singleton "Game" — the one GameState + GameContent

resources/
  defs/                                Resource "schema" classes — the shape of content, not the data
    enemy_def.gd                       class_name EnemyDef extends Resource
    trap_def.gd                        class_name TrapDef extends Resource
    wave_entry.gd                      class_name WaveEntry extends Resource
    wave_def.gd                        class_name WaveDef extends Resource
    auto_farmer_def.gd                 class_name AutoFarmerDef extends Resource
    economy_config.gd                  class_name EconomyConfig extends Resource
    game_content.gd                    class_name GameContent extends RefCounted (runtime container, not a .tres)
  content/                             The actual authored data — .tres instances of the classes above
    enemies/*.tres                     4 enemies: ant, roach, wasp, radioactive_roach
    traps/*.tres                       3 traps: poison_border, sticky_mat, kitchen_pit
    waves/*.tres                       4 authored waves, keyed by invasion_level 0-3
    economy/economy_config.tres        Starting money/health/rent/desk income + 2 auto-farmers

state/
  game_state.gd                        class_name GameState extends Resource — the whole run, flattened
  owned_trap.gd                        class_name OwnedTrap extends Resource
  placed_trap.gd                       class_name PlacedTrap extends Resource

systems/                               PURE, engine-free logic — no Node/scene-tree dependency
  content_loader.gd                    Loads + validates all .tres content at boot
  save_system.gd                       user://save.json read/write, versioned
  economy.gd                           Rent, desk income, overnight auto-farm income
  waves.gd                             Wave selection/scaling + wave-vs-traps resolution
  loss.gd                              The two loss conditions (see "Known quirks" below)
  day_director.gd                      Phase transitions, rent charge, sleep/escalation, save

scenes/
  main/Main.tscn, Main.gd              Persistent root: Hud + swappable PhaseContainer + GameOverOverlay
  boot/Boot.tscn, Boot.gd               One-time redirect to Main.tscn on startup
  morning/Morning.tscn, Morning.gd      Buy traps, deploy, advance to afternoon
  afternoon/Afternoon.tscn, Afternoon.gd  DEFEND vs WORK, outcome readout, advance to night
  night/Night.tscn, Night.gd            Install auto-farmers, sleep (save + escalate)
  ui/hud/Hud.tscn, Hud.gd                3-line status readout, shared across all phases
  ui/game_over/GameOverOverlay.tscn, .gd Full-screen "RUN OVER" overlay, shared across all phases
  ui/shop_button/ShopButtonRow.tscn, .gd  One reusable "Buy X" / "Install X" row, used by both shop lists
```

## The `Game` autoload

`autoload/Game.gd` is registered in `project.godot` under `[autoload]` and is
reachable from any script as the bare identifier `Game` (no `get_node()`
needed — this is Godot's global-singleton mechanism). It holds exactly two
things:

- `state: GameState` — the entire mutable run.
- `content: GameContent` — everything loaded from `resources/content/`.

Because autoloads always finish their own `_ready()` before any scene's
`_ready()` runs, `Game._ready()` is where content gets loaded and the save
gets loaded-or-created — every other script can assume `Game.state` and
`Game.content` already exist by the time it runs.

`Game` also exposes three signals so UI can react without being torn down
and rebuilt:

- `state_changed` — emitted after any mutation (buy, deploy, install,
  sleep, etc.). `Hud` listens to this to refresh its 3 lines.
- `phase_changed(new_phase)` — emitted when `state.phase` changes.
  `Main.gd` listens to this to swap the visible phase scene; `Hud` also
  listens, to refresh its phase label.
- `run_over_changed(is_over)` — emitted when the `GameOverOverlay` should
  actually show or hide. Deliberately **not** automatic — see "Deferred
  game-over" below.

## Content layer: `resources/defs/` vs `resources/content/`

This mirrors the original's `data/schemas.ts` (types) vs `data/*.json`
(data) split, just using Godot's native `Resource` system instead of
Zod-validated JSON:

- `resources/defs/*.gd` are the **schema** — `@export`-typed fields on a
  `Resource` subclass. Godot's Inspector enforces the field *types*
  automatically (you can't put a string where an int is expected), which is
  most of what Zod was doing in the original.
- `resources/content/*.tres` are the **data** — actual instances, editable
  in the Inspector or as plain text (they're a simple text format; see the
  in-session discussion on hand-editing them).
- `GameContent` (`resources/defs/game_content.gd`) is the one exception —
  it's a plain `RefCounted`, not a `Resource`, because it's assembled at
  runtime by `ContentLoader` (not authored by hand), and holds `Dictionary`
  lookups (`enemies`, `traps` keyed by id) — GDScript's equivalent of the
  original's `Map<string, T>`.

`systems/content_loader.gd`'s `ContentLoader.load_content()` scans the
`enemies/`, `traps/`, `waves/` folders, builds those keyed Dictionaries plus
a `waves` array sorted by `invasion_level`, loads the single
`economy_config.tres`, then does the one check typing *can't* enforce:
every `WaveEntry.enemy_id` must actually exist in `enemies`. If not, it
`push_error`s (readable message naming the bad level/id) and returns `null`
— `Game._ready()` treats a `null` content load as fatal and quits, matching
the original's "throw loudly at boot, don't chase an undefined three scenes
deep."

## State layer: `state/game_state.gd`

`GameState` is a flat `Resource` "data bag" — the original's nested
TypeScript interfaces (`home`, `player`, `rent`, `invasion`) got flattened
into prefixed fields (`home_integrity`, `home_max`, `rent_next_due_day`,
`invasion_level`, ...) to keep the save format simple. `OwnedTrap` and
`PlacedTrap` stay as their own small `Resource` classes since they're
array elements with multiple fields each.

**Save/load** (`systems/save_system.gd`) is deliberately plain JSON to
`user://save.json`, via explicit `GameState.to_dict()` /
`GameState.from_dict(d)` methods — not `ResourceSaver.save()` to a `.tres`.
Reason: a `.tres` save embeds the script's class path, so restructuring
`GameState`'s script later (exactly what version bumps are for) can make old
`.tres` saves load with silently wrong/null fields. Plain JSON + a
`version` field check before touching any real data is a clean, explicit
"reject old saves" gate — `SaveSystem.load_game()` returns `null` on any
version mismatch, missing file, or parse error, same contract as the
original's `loadGame()`.

## Systems layer: `systems/*.gd`

Each is a `class_name X extends RefCounted` with only `static func`s — no
instantiation, no scene-tree dependency, called directly like
`Economy.desk_job_income(config)`. This is a direct port of the original's
"pure w.r.t. Phaser" TS modules, and stays just as unit-testable in
isolation (see "Verifying changes" below).

- **`Economy`** — `desk_job_income`, `compute_overnight_income`,
  `apply_rent_if_due` (returns a `Dictionary` — GDScript has no lightweight
  struct type, so ad hoc multi-value returns use `{"key": value, ...}`
  throughout these systems).
- **`Waves`** — `wave_for_invasion_level` (pick the authored wave, or scale
  the last authored one by `1 + max(0, level - lastLevel) * 0.35`, rounding
  counts **up** with `ceil`); `resolve_wave` (shared damage-pool model:
  every placed trap contributes `damage * remaining_durability` to one
  pool; enemies are chewed through in list order — pool covers the hit,
  enemy dies and its `money_reward` is tallied for **display only**; pool
  doesn't cover it, enemy breaches and its `damage` hits home integrity).
  Durability is then drained **sequentially through the placed-traps array
  in order**, one point at a time, not proportionally across traps — this
  matters if you ever add multiple trap types to the same defense, since
  earlier traps in the array get fully spent before later ones are touched
  at all.
- **`Loss`** — `check_loss` (home takeover beats player death in priority;
  returns `""` for "no loss" since GDScript strings have no separate null),
  `apply_loss` (stamps `run_over` + `loss_reason`).
- **`DayDirector`** — `start_morning` (rent check → loss if unpaid),
  `to_afternoon`/`to_night` (trivial phase setters), `sleep` (overnight
  income → escalate invasion → advance day → save), `escalate_invasion`
  (bump `invasion_level`, unlock any enemy whose `unlocks_at_invasion_level`
  now qualifies).

## Scene architecture: persistent root, not `change_scene_to_file` per phase

`Main.tscn` is a persistent root containing one `Hud` instance, one
swappable `PhaseContainer` (Morning/Afternoon/Night get instanced in and
`queue_free()`'d out as `state.phase` changes), and one `GameOverOverlay`
instance. `Boot.tscn` is the project's actual "Main Scene" setting, and its
only job is a **deferred** one-time `change_scene_to_file` to `Main.tscn`
(deferred because calling it synchronously from the main scene's own
`_ready()` tries to `remove_child()` a node that's still being added,
which errors).

Why a persistent root instead of swapping the whole scene per phase: the
original redraws its HUD and re-checks game-over in *every single* Phaser
scene. In Godot it's cleaner to have exactly one `Hud` and one
`GameOverOverlay`, reacting to `Game` signals, while only the center content
actually changes — this avoids a full scene-tree teardown/rebuild (and the
associated one-frame flicker) on every Morning→Afternoon→Night transition,
which happens constantly in this game's core loop.

Each phase script (`Morning.gd`, `Afternoon.gd`, `Night.gd`) checks
`Game.get_state().run_over` at the very top of `_ready()` and bails out
immediately if true, so a phase scene freshly instanced after a loss doesn't
redo work (e.g. re-charging rent) or build dead UI underneath the overlay.

### Deferred game-over

`Game.notify_state_changed()` (called after every mutation) does **not**
automatically show the overlay, even if the mutation just set
`run_over = true`. Showing the overlay is a separate explicit call,
`Game.notify_run_over()`. This split exists because of the DEFEND/WORK
outcome panel in `Afternoon.gd`: when a wave breach drops home integrity to
0, the player should see the "Killed X, breached Y" readout *first*, and
only see "RUN OVER" after dismissing it via the panel's continue button —
so `Afternoon.gd` deliberately delays `notify_run_over()` until then. A
rent-miss loss (in `Morning.gd`) has no such readout to wait for, so it
calls `notify_run_over()` immediately after `notify_state_changed()`.

### Reusable UI: `ShopButtonRow`

One `HBoxContainer` scene (`Label` + `Button`, a `configure(id, text,
button_text, enabled)` method, and a `pressed_buy(item_id)` signal) is
instanced repeatedly for **both** the Morning trap shop and the Night
auto-farmer list — no duplicated "buy row" scene. Re-populating the
container after a purchase (`_populate_shop()` / `_populate_farmers()`) is
the narrow replacement for the original's `this.scene.restart()`: it only
rebuilds the dynamic row list, not the whole scene.

## Known quirks / intentional design decisions

These match the original exactly and are **not** bugs — flagged here so
nobody "fixes" them later without meaning to:

- **Kill money is display-only.** `Waves.resolve_wave`'s `money_earned`
  (from enemy `money_reward`) is shown in the Afternoon outcome text but
  never credited to `state.money`, in either DEFEND or WORK. The player
  only earns money from the WORK branch's `desk_job_income` and from
  installed auto-farmers overnight — confirmed intentional during the port,
  not an oversight.
- **`player_death` is currently unreachable.** `Loss.check_loss` checks
  `player_health <= 0`, but no code path anywhere decrements
  `player_health` — it's dead/future code carried over from the original,
  which had the same gap. `GameState.player_health`/`player_max` exist and
  are initialized from the economy config, just never mutated.
- **`rent_next_due_day` starts at `rent_interval_days`**, not `1 +
  rent_interval_days` — "first rent falls due after one interval," exactly
  matching the original's `GameState.ts` comment.

## Mapping back to the original TypeScript project

| Original (`../insect-defense/src/`) | This project |
|---|---|
| `main.ts` (Phaser config + scene list) | `project.godot` `[autoload]`/`run/main_scene` + `scenes/main/Main.gd` |
| `core/registry.ts` (`scene.registry` wrapper) | `autoload/Game.gd` |
| `core/GameState.ts` | `state/game_state.gd` |
| `core/save.ts` | `systems/save_system.gd` |
| `core/DayDirector.ts` | `systems/day_director.gd` |
| `data/schemas.ts` (Zod) | `resources/defs/*.gd` (`@export`-typed `Resource` classes) |
| `data/*.json` | `resources/content/**/*.tres` |
| `data/loader.ts` | `systems/content_loader.gd` |
| `systems/economy.ts` | `systems/economy.gd` |
| `systems/waves.ts` | `systems/waves.gd` |
| `systems/loss.ts` | `systems/loss.gd` |
| `scenes/BootScene.ts` | `scenes/boot/Boot.gd` (now mostly vestigial — see README) |
| `scenes/MorningScene.ts` | `scenes/morning/Morning.gd` |
| `scenes/AfternoonScene.ts` | `scenes/afternoon/Afternoon.gd` |
| `scenes/NightScene.ts` | `scenes/night/Night.gd` |
| `ui/widgets.ts` (`makeButton`, `drawHud`, `showGameOverIfNeeded`) | `scenes/ui/shop_button/`, `scenes/ui/hud/`, `scenes/ui/game_over/` |

## Verifying changes

There's no in-repo automated test suite yet (the original didn't have one
either). The port was verified with a temporary headless driver script that
exercised every system function against known values from the original
JSON content (rent math, wave resolution/drain arithmetic, invasion
escalation/unlocks, save/load round-trip, both loss conditions, wave-scaling
fallback) plus a clean headless boot of the real scene tree — all of which
passed before this project was committed. If you want the same kind of
check after a change, the pattern is: a temporary `Node` script set as
`run/main_scene`, calling the `systems/*.gd` static functions directly with
known inputs and asserting on the outputs, run via
`Godot_v4.7-stable_win64_console.exe --headless --path .` — then restore
`run/main_scene` back to `res://scenes/boot/Boot.tscn` afterward.
