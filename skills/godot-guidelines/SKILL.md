---
name: godot-guidelines
description: Godot Engine coding conventions for GDScript and C#, naming rules, comment style, scene structure, signal conventions, and best practices for Godot 4.x. This skill overrides external style guides where it defines rules. Load when writing or reviewing Godot Engine code (GDScript or C#).
---

# Godot Engine Guidelines

This skill covers **both GDScript and C#** conventions for Godot 4.x. Rules apply to the language in use unless explicitly marked as GDScript-only or C#-only.

## Style Priority (Read First)

When writing or reviewing Godot code in a project that uses this skill:

Follow the project's rules. Apply this skill to GDScript and to C# code that integrates with Godot, including nodes, resources, signals, and editor-facing APIs. Use `csharp-guidelines` for engine-independent C# and for general C# topics this skill does not cover. Use the references below for other topics.

## Core References

Use these when this skill does not cover the topic:

- [Godot 4.x GDScript Reference](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html) — GDScript language reference
- [Godot 4.x C# Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/index.html) — C# in Godot reference
- [Godot GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html) — official GDScript formatting and naming conventions
- [Godot Best Practices](https://docs.godotengine.org/en/stable/tutorials/best_practices/index.html) — scene structure, autoloads, project organization

## Godot Version Detection

- **Identify the target engine version.** Check the project's engine pin, CI or export environment. In `project.godot`, inspect `application/config/features` as a hint. `config_version` identifies the project format. Check the actual engine minor version before using a newly introduced API.
- **Use features supported by that version.** For example, [Godot 4.0 supports `PackedScene.instantiate()`](https://docs.godotengine.org/en/4.0/classes/class_packedscene.html) and [Godot 4.4 adds typed dictionaries](https://godotengine.org/releases/4.4/).
- **Replace legacy idioms** — `PackedScene.instantiate()` over `.instance()`, typed arrays over untyped, `@onready` over `_ready()` initialization blocks, `signal` keyword over `add_user_signal()`, `super()` over explicit parent class name calls, `%UniqueName` over `get_node("../../../Some/Path")`.

## Naming Conventions

### GDScript Naming Table

| Element | Convention | Example |
| --- | --- | --- |
| **File names** | snake_case | `player_controller.gd` |
| **Class names** | PascalCase | `class_name PlayerController` |
| **Node names (in scene)** | PascalCase | `Camera3D`, `Player`, `HealthBar` |
| **Functions** | snake_case | `func load_level():` |
| **Variables** | snake_case | `var particle_effect` |
| **Signals** | snake_case (past tense) | `signal door_opened` |
| **Constants** | CONSTANT_CASE | `const MAX_SPEED = 200` |
| **Enum names** | PascalCase | `enum Element` |
| **Enum members** | CONSTANT_CASE | `{EARTH, WATER, AIR, FIRE}` |
| **@onready variables** | snake_case | `@onready var health_bar = $HealthBar` |
| **Static variables** | snake_case | `static var instance_count = 0` |
| **Inner classes** | PascalCase | `class StateMachine:` |

### C# Naming Table

| Element | Convention | Example |
| --- | --- | --- |
| **Namespaces** | PascalCase | `namespace Game.Combat` |
| **Classes / Structs** | PascalCase. Classes derived from `GodotObject` require `partial`. | `public partial class PlayerController : CharacterBody3D` |
| **Methods** | PascalCase | `void LoadLevel()` |
| **Properties** | PascalCase | `public float MaxHealth { get; set; }` |
| **Custom signals** | PascalCase delegate with an `EventHandler` suffix | `[Signal] public delegate void DoorOpenedEventHandler();` |
| **Constants** | PascalCase | `public const float MaxSpeed = 200f` |
| **Private fields** | _camelCase (underscore prefix) | `private float _currentHealth` |
| **Local variables** | camelCase | `var particleEffect` |
| **Interfaces** | I prefix | `public interface IDamageable` |
| **Enum types** | PascalCase | `public enum Element` |
| **Enum members** | PascalCase | `Earth, Water, Air, Fire` |

### Semantic Naming Rules

Format is not enough — a name must convey **meaning and intent**:

- **Booleans** (variables and predicate functions) read as a yes/no question: prefix with `is_` / `has_` / `can_` / `should_` in GDScript, or `is` / `has` / `can` / `should` in C#.
  - GDScript: `is_open`, `has_key`, `can_jump`, `should_respawn`
  - C#: `IsOpen`, `HasKey`, `CanJump`, `ShouldRespawn`
  - Avoid negated names — prefer `is_alive` over `is_not_dead` (double negatives in conditions are error-prone).
- **Action functions** are verbs or verb-phrases — `load_level()`, `apply_damage()`, `spawn_enemy()`, `reset_state()`.
- **Getters / setters**: use `get_` / `set_` prefix in GDScript (idiomatic) — `get_health()`, `set_speed()`. In C#, use properties — `Health { get; set; }`.
- **Factory / instantiation functions**: `create_xxx()` / `make_xxx()` — `create_bullet()`, `make_enemy()`.
- **Counts / sizes / indices**: `xxx_count` for counts, `xxx_size` for dimensions, `xxx_idx` for indices — `enemy_count`, `pool_size`, `target_idx`.
- **Units in the name** whenever a bare number is ambiguous — `timeout_sec`, `speed_pps` (pixels per second), `damage_hp`.
- **Scope governs length** — short names in tight scopes (`i`, `v`, `t`, `dt`), descriptive names for wider scope (`current_health`, `max_jump_velocity`).
- **Abbreviations**: spell words out except well-established ones — `id`, `hp`, `pos`, `rot`, `col`, `anim`, `sfx`, `vfx`, `ui`.

## File Layout and Organization

### GDScript File Order (Top → Bottom)

Every `.gd` file must follow this exact order:

1. `@tool`, `@icon`, `@static_unload` (annotations)
2. `class_name` (optional)
3. `extends` (required, placed on its own line)
4. `##` doc comment for the script (double-hash)
5. `signal` declarations
6. `enum` definitions
7. `const` declarations
8. `static var` declarations
9. `@export var` declarations
10. Regular `var` declarations
11. `@onready var` declarations
12. `_static_init()` (static constructor)
13. Static methods
14. Overridden built-in virtual methods in lifecycle order:
    - `_init()`
    - `_enter_tree()`
    - `_ready()`
    - `_process(delta)`
    - `_physics_process(delta)`
    - Other virtuals (`_input`, `_unhandled_input`, `_exit_tree`, etc.)
15. Custom public methods
16. Custom private methods
17. Signal callback methods (named `_on_{node_name}_{signal_name}`)
18. Inner classes

### C# File Order (Top → Bottom)

1. `using` statements (System first, then Godot, then project)
2. `namespace` declaration
3. Class doc comment (`///`)
4. `[Signal]` delegate declarations
5. `[Export]` fields and properties
6. Private fields
7. Constructor (`public override void _Ready()` or similar)
8. Public methods
9. Private methods
10. Signal callback methods (`On{NodeName}{SignalName}`)
11. Nested types

### GDScript Formatting Rules

- **Indentation**: Use **TABS** for indentation. Never use spaces for indentation in GDScript.
- **Line length**: 100 characters maximum; prefer 80.
- **Blank lines**: Two blank lines between functions and classes. One blank line inside functions to separate logical sections.
- **Boolean operators**: Use `and`, `or`, `not` — never `&&`, `||`, `!`.
- **Strings**: Prefer double quotes `"` for strings unless the string contains double quotes.
- **Floats**: Always include a leading or trailing zero — `0.234`, `13.0`, not `.234` or `13.`
- **Large numbers**: Use underscores — `1_234_567_890`, `0x7FFF_FFFF`.
- **Arrays, dictionaries, enums**: Trailing comma on the last line.
- **Function calls**: No space before parentheses — `func_name(arg)`, not `func_name (arg)`.

### C# Formatting Rules

- **Indentation**: Use **4 SPACES** for indentation. Never use tabs in C#.
- **Brace style**: Allman style — opening brace on the next line.
- **Line length**: 120 characters maximum.
- **Namespaces**: Use file-scoped namespaces (`namespace Game.Combat;`) on a single line.
- **String interpolation**: Prefer `$"Health: {_health}"` over concatenation.

## Project Organization

- **Folder and file names**: Use **snake_case** for all folders and files — `player/player_controller.gd`, `ui/main_menu.tscn`.
- **Node names**: Use **PascalCase** in the scene tree — `Player`, `Camera3D`, `HealthBar`, `SpawnPoint`.
- **Asset grouping**: Group by **feature or character**, not by asset type.
  ```
  # Good: Group by feature
  player/
      player_controller.gd
      player_model.tscn
      player_texture.png
      player_sounds/
          jump.wav
          hurt.wav
  enemy/
      enemy_base.gd
      enemy_slime.tscn
      enemy_boss.tscn

  # Bad: Group by type
  scripts/   player_controller.gd   enemy_base.gd
  scenes/    player.tscn   enemy_slime.tscn
  textures/  player.png
  ```
- **Third-party content**: Place in `addons/` folder. The editor treats this directory specially.
- **Exclude from import**: Use `.gdignore` files to exclude folders from the Godot resource import system (e.g., raw source assets not meant for the engine).
- **One script per file**, named after the class — `player_controller.gd` → `PlayerController`. Exception: small inner classes that only serve the parent class.

## Comment Conventions

### What Must Be Documented

**Mandatory** — these MUST carry a `##` doc comment (GDScript) or `///` doc comment (C#):

- **All scripts with `class_name`** — purpose, dependencies, and lifecycle expectations.
- **All public functions** — behavior, parameters, return value, and side effects.
- **All exported variables** — what the value controls and its valid range.
- **All signals** — when they are emitted and what data they carry.
- **Enums and their values** — the meaning of each variant.
- **Complex algorithms or state machines** — the invariants and transitions.

**Optional / discouraged**:

- Trivial getters/setters and self-documenting code need no comment.
- Never write a comment that merely restates the code (`# increment i`).
- Comment the **why**, not the **what** — and prefer renaming over explaining a poor name.
- Use `# TODO(username):` / `# FIXME(username):` with an owner for deferred work.

### General Rules

- **GDScript**: Use `##` for doc comments (above the declaration), `#` for inline and implementation comments. Do **not** use `""" """` multi-line strings as doc comments.
- **C#**: Use `///` for XML doc comments on types and public members; use `//` for inline comments. Do **not** use `/* */` block comments.
- Write documentation as **plain sentences** — do **not** use metadata prefixes like `brief:`, `details:`, or `see:` on comment lines.
- Prefer **English** for all comments.
- **No decorative section banners** — do not use lines like `# ---------- Section ----------` or `# ==== Foo ====`. Use a normal comment sentence if a boundary needs explaining, or let the code structure speak for itself.

### Script Documentation (GDScript)

```gdscript
## Controls player movement, jumping, and interaction with the world.
##
## Depends on an [InputManager] autoload for input abstraction and
## expects a [CharacterBody3D] node named "Graphics" as a child.
class_name PlayerController
extends CharacterBody3D
```

### Signal Documentation

```gdscript
## Emitted when the character's health reaches zero and death
## animation completes. param source: the damage source that
## caused the final blow.
signal died(source: Node)
```

### Function Documentation

```gdscript
## Applies damage to the entity and emits [signal health_changed].
## If health drops to zero or below, [signal died] is emitted.
func apply_damage(amount: float, source: Node = null) -> void:
```

## Decomposition Granularity

- **Scene**: one cohesive responsibility. A scene should answer "what does this scene represent?" not "what nodes are inside?". Avoid dumping unrelated functionality into a single scene.
- **Script file**: under **800 lines** (global rule). Split when a script accumulates multiple unrelated concerns. Use composition (child nodes with their own scripts) rather than monolithic controllers.
- **Class**: a single responsibility. If a class handles both input processing AND inventory management, split it. Keep the public interface minimal (Minimal Export Principle) — roughly **≤ 10–15 public methods**.
- **Function**: under **50 lines** (global rule), at a **single level of abstraction**, with **≤ 4 parameters** — bundle more into a dictionary or a small Resource.
- **Node over monolithic script** — when a character needs health, movement, and inventory, give it three child nodes (`HealthComponent`, `MovementComponent`, `InventoryComponent`) rather than one 500-line controller script.

## Signal Conventions

Signals are Godot's primary mechanism for decoupled communication. Use them correctly:

### Naming

- **Past tense** for completed actions — `door_opened`, `enemy_killed`, `level_loaded`.
- **Present/passive** for state changes — `health_changed`, `score_updated`, `visibility_changed`.
- **_started / _finished** for action phases — `attack_started`, `animation_finished`.
- Signals are **snake_case** in GDScript, **PascalCase** in C#.

### Callback Naming

- GDScript: `_on_{node_name}_{signal_name}` — `_on_health_component_health_changed(new_health)`.
- C#: `On{NodeName}{SignalName}` — `OnHealthComponentHealthChanged(float newHealth)`.

### Communication Pattern

- **"Call down, signal up"** — parents call methods on children; children emit signals that parents connect to.
- Use signals for **"responding"** (notifications, events, state changes).
- Use methods and `Callable` for **"starting"** (commands, requests, actions).
- **Never call methods across distant branches of the scene tree** — emit a signal upward and let a common ancestor route the call downward.

### Declaration

```gdscript
# GDScript: Past-tense signal with typed parameters.
signal health_changed(new_health: float, old_health: float)
signal died(source: Node)
```

```csharp
// C#: Use [Signal] delegate for custom signals.
[Signal] public delegate void HealthChangedEventHandler(float newHealth, float oldHealth);
[Signal] public delegate void DiedEventHandler(Node source);

// Emit by calling the generated EmitSignalXxx helper.
EmitSignalHealthChanged(newHealth, oldHealth);
```

### Connecting Signals

```gdscript
# GDScript: Connect via editor or in code.
health_component.health_changed.connect(_on_health_changed)

# Disconnect when done.
health_component.health_changed.disconnect(_on_health_changed)
```

```csharp
// C#: Use C# events (preferred over Connect/Disconnect).
// Subscribe:
GetNode<HealthComponent>("HealthComponent").HealthChanged += OnHealthChanged;
// Unsubscribe:
GetNode<HealthComponent>("HealthComponent").HealthChanged -= OnHealthChanged;
```

## Scene Structure Best Practices

- **Self-contained scenes** — a scene should work in isolation when run. Use exported variables and signals for all external dependencies; never rely on hardcoded paths to nodes outside the scene.
- **SOLID principles apply to scenes** — each scene should have a single, well-defined purpose.
- **"Call down, signal up"** is the canonical Godot communication pattern.
- **Composition via child nodes** — build complex behavior by composing small, reusable sub-scenes (components).
- **Use `%` unique names** for important nodes within a scene — `$%PlayerCamera` instead of `$CameraRoot/Camera3D`. This makes refactoring and scene restructuring safe.
- **Avoid deep nesting** — if a node path exceeds 3 levels, reconsider your scene hierarchy.
- **Scripts attach to the root node** of their scene — if a script uses `$Child/Node`, that child should be a direct dependency of the scene, not an external assumption.

## @export and Editor Integration

- **Use `@export` for all configurable values** — speeds up iteration and empowers designers.
- **Group exports logically** with `@export_group` and `@export_subgroup`:

```gdscript
@export_group("Movement")
@export var move_speed: float = 400.0
@export var acceleration: float = 0.2

@export_group("Combat")
@export var max_health: int = 100
@export var damage_resistance: float = 0.0
```

- **Use typed exports** — `@export var health: int`, not `@export var health = 100` (untyped).
- **Export node paths** for scene references — `@export var target: NodePath`. Prefer node paths over hardcoded `get_node()` paths.
- **In C#**, use `[Export]` for fields — `[Export] private float _moveSpeed = 400f;`. Use `[Export] private NodePath _targetPath;` for node paths.

## Static Typing

- **Prefer `:=`** (inferred type) in GDScript when the type is unambiguous from the assignment.
- **Use explicit `: Type`** when the type is not obvious from context — function parameters, signal parameters, empty arrays.
- **Declare return types** with `-> ReturnType` on all public functions.
- **Cast `get_node()` results** with `as` — `$Sprite as Sprite2D` or `get_node("Sprite") as Sprite2D`. Use `%` unique names to avoid `get_node()` entirely.
- **Use typed arrays** — `var enemies: Array[Enemy] = []`, not `var enemies = []`. Typed arrays are faster and catch type errors at compile time.
- In C#, always use explicit types for public members. `var` is acceptable for local variables where the type is obvious from the right-hand side.

## Error Handling

- **GDScript `assert()`** — for invariant checks during development. `assert(speed > 0, "Speed must be positive")`. Assertions are stripped in release builds. Never use `assert()` for user-facing errors.
- **GDScript `push_error()` / `push_warning()`** — for runtime issues that should appear in the editor debugger Errors tab. `push_error("Failed to load save file: %s" % path)`. Does not halt execution.
- **C#** — use `Debug.Assert()` for invariant checks. Throw exceptions for unrecoverable programming errors. Use `try`/`catch` at API boundaries for expected failures.
- **Validate at boundaries** — check input parameters at the top of public functions. Fail fast with clear messages:
  ```gdscript
  func apply_damage(amount: float) -> void:
      assert(amount >= 0, "Damage amount must be non-negative, got %s" % amount)
  ```
- **Graceful degradation** — when a node reference or resource is missing, log a warning and disable the feature rather than crashing. Use `is_instance_valid()` and `if node:` checks:
  ```gdscript
  @onready var music_player: AudioStreamPlayer = $MusicPlayer

  func play_music(track: AudioStream) -> void:
      if not is_instance_valid(music_player):
          push_warning("MusicPlayer not found, audio disabled")
          return
      music_player.stream = track
      music_player.play()
  ```
- **Avoid `return null`** from public methods that promise a result. Use a typed optional pattern (return a `Result` Resource or signal an error) instead.
- **Signal errors** for async operations — if a level load fails, emit `level_load_failed(error_message: String)` rather than crashing. Callers decide how to handle it.

## Resource Management and Node Lifecycle

- **queue_free() over free()** — always use `queue_free()` to safely remove nodes. `queue_free()` defers deletion to the end of the frame, preventing use-after-free bugs. `free()` is immediate and dangerous.
- **is_instance_valid()** — check that a node or object still exists before accessing it, especially after `queue_free()` calls or when holding cached references. In C#, use `GodotObject.IsInstanceValid()`.
- **Ownership is visual** — in the SceneTree, a parent node owns its children. When a parent is freed, all children are freed automatically. Design your scene hierarchy so ownership matches lifecycle.
- **WeakRef for cross-scene references** — use `weakref()` in GDScript (or `WeakRef` in C#) when holding a reference to a node that may be freed independently. Always resolve `get_ref()` and check for `null`.
- **Resource lifecycle** — Resources loaded via `load()` or `preload()` are cached and reference-counted by the engine. Use `Resource.take_over_path()` to replace a cached resource. Call `.duplicate()` for independent copies. Resources are NOT freed when the node that loaded them is freed.
- **RefCounted vs manual** — `RefCounted` (and its subclass `Resource`) is automatically freed when no references remain. Nodes (`Node`) require explicit `queue_free()`.
- **Disconnect signals on cleanup** — in `_exit_tree()`, disconnect any manually-connected signals to prevent dangling references:
  ```gdscript
  func _exit_tree() -> void:
      if health_component.health_changed.is_connected(_on_health_changed):
          health_component.health_changed.disconnect(_on_health_changed)
  ```
  In C#, unsubscribe events in `_ExitTree()` (as shown in Signal Conventions).
- **Node configuration before `add_child()`** — initialize properties on a newly-instantiated node before adding it to the SceneTree. Adding to the tree triggers `_ready()` and `_enter_tree()` callbacks.

## Component and Interface Design

- **Dependency injection via @export** — inject dependencies (nodes, Resources, configuration) through `@export` variables rather than hardcoded `get_node()` paths or global lookups. This makes scenes self-documenting and testable.
  ```gdscript
  # Good: Dependency injected, testable.
  @export var health_component: HealthComponent
  @export var bullet_scene: PackedScene

  # Bad: Hardcoded dependency.
  @onready var health_component: HealthComponent = $"../../Player/HealthComponent"
  ```
- **Signals as interfaces** — signals define a scene's public contract. "I will emit `health_changed(float, float)` when my health changes." Callers depend on the signal, not the implementation. This is Godot's equivalent of "accept interfaces, return structs."
- **Small, focused nodes** — prefer nodes with 1–3 public methods + 1–3 signals. A `HealthComponent` exposes `apply_damage()` and `heal()`, and emits `health_changed` and `died`. That's the entire interface.
- **Consumer-side signal connection** — the parent or orchestrator connects signals, not the emitting node. The emitting node declares signals without knowing who listens.
- **Avoid node path coupling** — never write `get_node("../../../Some/Node")`. Use one of these ranked by safety:
  1. `@export var target: NodeType` — editor-assigned, refactor-safe.
  2. `$%UniqueName` — survives scene restructuring.
  3. `@onready var child := $DirectChild` — only for direct children.
  4. Signal emission upward — let a common ancestor route the call down.
- **Scene inheritance** — use inherited scenes for variant prefabs (e.g., `enemy_base.tscn` → `enemy_slime.tscn`). Override methods or export values in the child scene. Keep inheritance shallow (≤ 2 levels).
- **Script over Resource for behavior, Resource over script for data** — if it has methods and signals, make it a script on a Node. If it's pure data (stats, dialogue, item definitions), make it a `Resource`.

## Design Patterns

Godot's architecture naturally encourages certain patterns. Apply these deliberately:

### Component Pattern (Primary Godot Pattern)

Instead of a monolithic controller script, split behavior into small, reusable child nodes:

```gdscript
# Instead of one 500-line Player.gd, compose:
# Player (CharacterBody2D)
#   ├── HealthComponent (Node)       — damage, healing, death signal
#   ├── MovementComponent (Node)     — input, velocity, move_and_slide
#   ├── WeaponComponent (Node)       — fire, reload, ammo
#   └── AnimationComponent (Node)    — state-driven animation blending
```

- Each component is a self-contained `class_name` Node with `@export` configuration and signals.
- The parent orchestrates by connecting component signals and calling component methods.
- Components can be reused across different character types (player, enemy, NPC).

### State Machine Pattern

Use a dedicated `StateMachine` node to manage character states cleanly:

```gdscript
class_name StateMachine
extends Node

signal state_changed(old_state: String, new_state: String)

var current_state: String
var states: Dictionary = {}

func add_state(name: String, state: State) -> void:
    states[name] = state
    state.state_machine = self

func transition_to(new_state: String) -> void:
    if current_state and states.has(current_state):
        states[current_state].exit()
    var old_state := current_state
    current_state = new_state
    if states.has(new_state):
        states[new_state].enter()
    state_changed.emit(old_state, new_state)

func _physics_process(delta: float) -> void:
    if states.has(current_state):
        states[current_state].physics_update(delta)
```

Prefer a dedicated `StateMachine` over `match`/`if` chains in `_process()`. The built-in `AnimationTree` with `AnimationNodeStateMachinePlayback` can also serve as a visual state machine for animation-driven states.

### Observer Pattern (Signals + EventBus)

Signals are Godot's built-in Observer pattern. For cross-system communication, add a dedicated `EventBus` autoload:

```gdscript
# autoload/event_bus.gd
extends Node

signal enemy_killed(enemy: Node, position: Vector2)
signal item_collected(item: Item, collector: Node)
signal level_completed(level_name: String)
```

Any node can `EventBus.enemy_killed.emit(...)` and any other node can `EventBus.enemy_killed.connect(...)`. This eliminates direct coupling between unrelated systems (e.g., the UI doesn't need a reference to every enemy).

**Rules for EventBus**: limit to genuinely cross-cutting events. Within a scene, use direct signals from the relevant node. An EventBus with 50+ signals suggests poor architecture.

### Object Pool Pattern

For frequently created/destroyed objects (bullets, particles, enemies), pre-instantiate a pool:

```gdscript
class_name ObjectPool
extends Node

@export var scene: PackedScene
@export var pool_size: int = 20

var _pool: Array[Node] = []

func _ready() -> void:
    for i in pool_size:
        var obj := scene.instantiate()
        obj.visible = false
        obj.process_mode = Node.PROCESS_MODE_DISABLED
        _pool.append(obj)

func acquire() -> Node:
    for obj in _pool:
        if not obj.visible:
            obj.visible = true
            obj.process_mode = Node.PROCESS_MODE_INHERIT
            return obj
    return null  # Pool exhausted (consider fallback instantiation)

func release(obj: Node) -> void:
    obj.visible = false
    obj.process_mode = Node.PROCESS_MODE_DISABLED
```

### Command Pattern

Use `Callable` and `Resource`-based commands for undo/redo systems, input rebinding, or replay:

```gdscript
class_name Command
extends Resource

func execute() -> void:
    pass  # Override in subclasses

func undo() -> void:
    pass  # Override in subclasses
```

### Strategy Pattern

Use `Resource`-based strategies for swappable behavior configured in the editor:

```gdscript
class_name MovementStrategy
extends Resource

func calculate_velocity(current: Vector2, input_dir: Vector2, speed: float, delta: float) -> Vector2:
    return Vector2.ZERO  # Override in subclasses
```

Create `LinearMovement`, `PlatformerMovement`, `TopDownMovement` as Resource subclasses. Assign via `@export var movement: MovementStrategy` and swap at runtime.

### Service Locator (Autoloads)

Covered in "Autoloads and Singletons" below. Prefer `@export` injection over autoload lookup when the dependency is scene-local. Reserve autoloads for truly global services.

## Concurrency and the Godot Thread Model

GDScript runs on the **main thread** — all `_process()`, `_physics_process()`, signal callbacks, and input handling execute sequentially in a single-threaded loop. This eliminates race conditions on scene data by design but requires care:

- **call_deferred()** — defer a method call to idle time (end of the current frame). Use when you need to wait for the SceneTree to settle (e.g., `call_deferred("add_child", node)` after modifying the tree inside a signal callback). In C#, use `CallDeferred(MethodName.AddChild, node)`.
- **`await` for asynchronous flow** — `await get_tree().create_timer(1.0).timeout` pauses the current function without blocking the main thread. The rest of the game continues running. Use for sequenced animations, cutscenes, and turn-based logic.
- **Threading (C# only)** — Godot's C# API is thread-safe for most operations through the `Godot.SynchronizationContext`. Use `Task.Run()` for heavy computation (pathfinding, procedural generation) and marshal results back to the main thread via `Godot.SynchronizationContext.Post()`.
- **Threading (GDScript)** — use the `Thread` class for background work: `Thread.new()`, `.start(callable)`, `.wait_to_finish()`. Never access the SceneTree, nodes, or Resources from a background thread. Pass primitive data only. Use `call_deferred()` to apply results on the main thread.
- **Mutex** — use `Mutex` for protecting shared data when multiple threads need access. Lock only for minimal critical sections.
- **Semaphore** — use `Semaphore` for producer-consumer patterns across threads (e.g., worker pool).
- **Document thread-safety** — mark any node or Resource that is accessed from non-main threads in its `##` doc comment.

## Autoloads and Singletons

- **Use autoloads for** globally accessible services — `InputManager`, `AudioManager`, `SaveSystem`, `EventBus`.
- **Avoid autoloads when** the system modifies data owned by other systems — this creates hidden coupling.
- **Alternatives to autoloads**:
  - `class_name` with `static func` for stateless utility functions.
  - Custom `Resource` singletons loaded via `preload()`.
  - The `owner` property to traverse upward to a shared ancestor.
- **Limit autoload count** — more than 5–7 autoloads suggests a design problem. Re-evaluate whether each truly needs global scope.
- **Initialize lazily** when possible — use `_ready()` in the autoload to set up state, not `_init()`.

## Performance and Memory

Optimize for clarity first; reach for these only on a measured-hot path:

- **Measure before optimizing** — use the Godot Profiler (`Debugger > Profiler`) and the Monitor tab. Never guess.
- **Avoid heavy work in `_process()`** — use signals, timers (`Timer` node), and `call_deferred()` instead of polling every frame.
- **Object pooling** for frequently created/destroyed objects (bullets, particles, enemies). Instantiate a pool at scene start and reuse instances.
- **Use `preload()`** for resources needed at parse time — `const BULLET_SCENE = preload("res://bullet.tscn")`. This avoids disk I/O during gameplay.
- **Cache node references in `@onready`** — never call `get_node()` (or `$Node`) inside `_process()` or `_physics_process()`.
- **Use typed arrays** (`Array[Enemy]`) — they are significantly faster than untyped arrays for iteration and element access.
- **Minimize node group usage** — groups are string-based lookups, slower than typed references. Use signals or direct references instead.
- **Free resources explicitly** — call `queue_free()` when done with nodes; use `Resource.take_over_path()` judiciously.
- **Profile draw calls** in 3D — merge static meshes, limit material variants, use LOD (level of detail) for distant objects.

## Tooling and Diagnostics

- **GDScript formatting**: Use `gdformat` (gdtoolkit) or `gdstyle`. Never hand-format GDScript.
- **GDScript LSP**: Built into the Godot editor. Enable external editor integration for VS Code (`godot-tools` extension) or JetBrains (`Godot Support` plugin).
- **C# diagnostics**: The Godot C# project includes built-in analyzers (GD0001–GD0402). Enable all. Run `dotnet format` for C# formatting.
- **Static analysis**: Use the Godot debugger's **Errors** tab to catch runtime issues. Run the project from the editor during development.
- **Project validation**: Use **Project > Tools > Fix Dependencies** and **Debug > Deploy with Remote Debug**.

## Default Plugins and Add-ons

**Library Selection Priority**:
1. **Godot built-in nodes and systems** (first choice)
2. **Well-established add-ons from the Asset Library** (second choice)

**Recommended Defaults**:

| Category | First Choice | Notes |
| --- | --- | --- |
| **Testing** | GUT (Godot Unit Testing) | De facto standard for Godot testing |
| **Dialogue** | Dialogic | Visual dialogue editor with timeline system |
| **Cinematics** | Phantom Camera | Camera system with built-in transitions and framing |
| **State Machines** | Nodot | General-purpose utility add-on with state machine support |
| **Input** | Input System (built-in) | Use Input Map in Project Settings |
| **Audio** | AudioStreamPlayer nodes | Built-in; use AudioManager autoload for global control |
| **UI** | Control nodes (built-in) | Use themes, containers, and anchors |
| **Pathfinding** | NavigationServer (built-in) | NavigationRegion2D/3D + NavigationAgent |
| **Serialization** | ConfigFile / Resource | Built-in; prefer typed Resources over dictionaries |
| **Tweening** | `create_tween()` (built-in) | Godot 4's built-in Tween system |

## Testing

- **Framework**: Use **GUT** (Godot Unit Testing) as the default testing framework. Install via the Asset Library or download from GitHub.
- **Test files**: Place in `tests/` at project root. Name test scripts `test_xxx.gd`.
- **Name tests by behavior, not by method** — `test_apply_damage_reduces_health`, not `test_apply_damage`.
- **Test scenes in isolation** — instantiate the scene under test, configure its dependencies, and assert on its behavior. Use `add_child()` to attach the test subject to the scene tree temporarily.
- **Mock signals** for loose-coupling tests — use `watch_signals()` in GUT to track signal emissions without needing the full dependency graph.
- **No real filesystem or network** in unit tests — use Resource-based data injection or test doubles.
- **Assert on signals** — `assert_signal_emitted(enemy, "died")` is often a better test than checking internal state.
- Tests are first-class code: same naming, layout, comment, and review bar as production code.
- In C# projects, also run standard .NET tests where applicable — use `NUnit` or `xUnit` for non-Godot C# logic.

## Godot-Specific Best Practices

### GDScript: Complete Example

```gdscript
## Manages player health, damage, and death state for a character.
##
## Emits [signal died] when health reaches zero. Connects to a
## [HealthBar] UI element via [signal health_changed].
class_name HealthComponent
extends Node

## Emitted when current_health changes value.
## param new_health: the health value after the change.
## param old_health: the health value before the change.
signal health_changed(new_health: float, old_health: float)

## Emitted when the character's health reaches zero.
signal died()

## Maximum health value for the component.
const MAX_HEALTH: float = 100.0

## Minimum time in seconds between damage ticks from the same source.
const DAMAGE_COOLDOWN_SEC: float = 0.5

@export_group("Health")
## Starting health for this character.
@export var max_health: float = MAX_HEALTH
## If true, the character cannot take damage.
@export var is_invincible: bool = false

var current_health: float
var _last_damage_time: float = 0.0

func _ready() -> void:
	current_health = max_health

## Applies damage to the character. Respects invincibility and
## cooldown. Returns the actual damage dealt (may be zero).
func apply_damage(amount: float) -> float:
	if is_invincible:
		return 0.0
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_damage_time < DAMAGE_COOLDOWN_SEC:
		return 0.0
	_last_damage_time = now

	var old_health := current_health
	current_health = maxf(current_health - amount, 0.0)
	health_changed.emit(current_health, old_health)

	if is_equal_approx(current_health, 0.0):
		died.emit()
	return old_health - current_health

## Restores health up to [member max_health].
func heal(amount: float) -> void:
	var old_health := current_health
	current_health = minf(current_health + amount, max_health)
	if not is_equal_approx(current_health, old_health):
		health_changed.emit(current_health, old_health)
```

```gdscript
## Character controller demonstrating @onready caching, signal
## connections, and typed node references.
class_name PlayerController
extends CharacterBody2D

const BULLET_SCENE := preload("res://bullet/bullet.tscn")

@export_group("Movement")
@export var move_speed: float = 400.0
@export var acceleration: float = 0.2

@export_group("Combat")
@export var fire_rate_sec: float = 0.15

# Cache node references with @onready and typed casts.
@onready var sprite: Sprite2D = $Sprite as Sprite2D
@onready var gun_marker: Marker2D = $%GunMarker as Marker2D
@onready var health_component: HealthComponent = $HealthComponent as HealthComponent

var _fire_timer: float = 0.0

func _ready() -> void:
	# Connect to child signals.
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)

func _process(delta: float) -> void:
	_handle_movement(delta)
	_handle_shooting(delta)

func _handle_movement(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var target_velocity := input_dir * move_speed
	velocity = velocity.lerp(target_velocity, acceleration)
	move_and_slide()

func _handle_shooting(delta: float) -> void:
	_fire_timer -= delta
	if Input.is_action_pressed("fire") and _fire_timer <= 0.0:
		_shoot()
		_fire_timer = fire_rate_sec

func _shoot() -> void:
	var bullet := BULLET_SCENE.instantiate() as Bullet
	bullet.global_position = gun_marker.global_position
	get_tree().current_scene.add_child(bullet)

func _on_health_changed(new_health: float, _old_health: float) -> void:
	# Modulate sprite red on damage, fading to white.
	var t := create_tween()
	var health_pct := new_health / health_component.max_health
	sprite.modulate = Color(1.0, health_pct, health_pct)
	t.tween_property(sprite, "modulate", Color.WHITE, 0.15)

func _on_died() -> void:
	# Disable collision and play death animation.
	set_physics_process(false)
	collision_layer = 0
```

### C#: Complete Example

```csharp
// Manages player health, damage, and death state for a character.

using Godot;

namespace Game.Components;

/// <summary>
/// Handles health, damage, and death for a character.
/// Emits <see cref="HealthChanged"/> and <see cref="Died"/> signals.
/// </summary>
public partial class HealthComponent : Node
{
    // Events (signals) — prefer C# events over Connect/Disconnect.
    [Signal] public delegate void HealthChangedEventHandler(float newHealth, float oldHealth);
    [Signal] public delegate void DiedEventHandler();

    // Exported fields for editor configuration.
    [ExportGroup("Health")]
    [Export] private float _maxHealth = 100f;
    [Export] private bool _isInvincible = false;
    [Export] private float _damageCooldownSec = 0.5f;

    // Private state.
    private float _currentHealth;
    private float _lastDamageTime;

    public float MaxHealth => _maxHealth;
    public float CurrentHealth => _currentHealth;
    public bool IsDead => _currentHealth <= 0f;

    public override void _Ready()
    {
        _currentHealth = _maxHealth;
    }

    /// <summary>
    /// Applies damage, respecting invincibility and cooldown.
    /// Returns the actual damage dealt.
    /// </summary>
    public float ApplyDamage(float amount)
    {
        if (_isInvincible) return 0f;

        var now = Time.GetTicksMsec() / 1000f;
        if (now - _lastDamageTime < _damageCooldownSec) return 0f;
        _lastDamageTime = now;

        var oldHealth = _currentHealth;
        _currentHealth = Mathf.Max(_currentHealth - amount, 0f);
        EmitSignalHealthChanged(_currentHealth, oldHealth);

        if (Mathf.IsEqualApprox(_currentHealth, 0f))
            EmitSignalDied();

        return oldHealth - _currentHealth;
    }

    /// <summary>
    /// Restores health up to MaxHealth.
    /// </summary>
    public void Heal(float amount)
    {
        var oldHealth = _currentHealth;
        _currentHealth = Mathf.Min(_currentHealth + amount, _maxHealth);
        if (!Mathf.IsEqualApprox(_currentHealth, oldHealth))
            EmitSignalHealthChanged(_currentHealth, oldHealth);
    }
}
```

```csharp
// Character controller demonstrating C# patterns in Godot.

using Godot;

namespace Game.Player;

public partial class PlayerController : CharacterBody2D
{
    // Use GD.Load for runtime resource loading (no preload in C#).
    private static readonly PackedScene BulletScene =
        GD.Load<PackedScene>("res://bullet/bullet.tscn");

    [ExportGroup("Movement")]
    [Export] private float _moveSpeed = 400f;
    [Export] private float _acceleration = 0.2f;

    [ExportGroup("Combat")]
    [Export] private float _fireRateSec = 0.15f;

    // [Export] for node references (preferred over GetNode).
    [Export] private Sprite2D _sprite;
    [Export] private Marker2D _gunMarker;
    [Export] private HealthComponent _healthComponent;

    private float _fireTimer;

    public override void _Ready()
    {
        // Connect via C# events, not Connect().
        _healthComponent.HealthChanged += OnHealthChanged;
        _healthComponent.Died += OnDied;
    }

    public override void _ExitTree()
    {
        // Always unsubscribe to prevent leaks.
        _healthComponent.HealthChanged -= OnHealthChanged;
        _healthComponent.Died -= OnDied;
    }

    public override void _Process(double delta)
    {
        var dt = (float)delta;
        HandleMovement(dt);
        HandleShooting(dt);
    }

    private void HandleMovement(float delta)
    {
        var inputDir = Input.GetVector("move_left", "move_right", "move_up", "move_down");
        var targetVelocity = inputDir * _moveSpeed;
        Velocity = Velocity.Lerp(targetVelocity, _acceleration);
        MoveAndSlide();
    }

    private void HandleShooting(float delta)
    {
        _fireTimer -= delta;
        if (Input.IsActionPressed("fire") && _fireTimer <= 0f)
        {
            Shoot();
            _fireTimer = _fireRateSec;
        }
    }

    private void Shoot()
    {
        // IsInstanceValid guards against freed nodes.
        if (!IsInstanceValid(BulletScene)) return;

        var bullet = BulletScene.Instantiate<Bullet>();
        bullet.GlobalPosition = _gunMarker.GlobalPosition;
        GetTree().CurrentScene.AddChild(bullet);
    }

    private void OnHealthChanged(float newHealth, float oldHealth)
    {
        var healthPct = newHealth / _healthComponent.MaxHealth;
        _sprite.Modulate = new Color(1f, healthPct, healthPct);
        var tween = CreateTween();
        tween.TweenProperty(_sprite, "modulate", Colors.White, 0.15);
    }

    private void OnDied()
    {
        SetPhysicsProcess(false);
        CollisionLayer = 0;
    }

    // Pattern matching for state handling.
    private void ProcessAnimation()
    {
        switch (Velocity)
        {
            case { X: > 0 }:
                _sprite.FlipH = false;
                break;
            case { X: < 0 }:
                _sprite.FlipH = true;
                break;
        }
    }
}
```

### Key Patterns Summary

```gdscript
# Good: preload at parse time, no disk I/O at runtime.
const SCENE = preload("res://scene.tscn")

# Good: typed cast on get_node result.
@onready var player: Player = $Player as Player

# Good: typed arrays for performance.
var enemies: Array[Enemy] = []

# Good: % unique name, no fragile path strings.
@onready var camera: Camera3D = $%PlayerCamera

# Good: past-tense signal with typed parameters.
signal score_changed(new_score: int, old_score: int)

# Good: inferred type with := when unambiguous.
var tween := create_tween()
var health_pct := current_health / max_health

# Bad: untyped variable.
var enemies = []

# Bad: get_node in _process (cache it in @onready).
func _process(delta: float) -> void:
    $Enemy.position += Vector2(1, 0)

# Bad: spaces for indentation in GDScript.
```

```csharp
// Good: C# events for signals instead of Connect/Disconnect.
_healthComponent.HealthChanged += OnHealthChanged;

// Good: [Export] for node references instead of GetNode.
[Export] private HealthComponent _healthComponent;

// Good: GD.Load<T>() for typed resource loading.
private static readonly PackedScene BulletScene = GD.Load<PackedScene>("res://bullet.tscn");

// Good: IsInstanceValid to check freed nodes.
if (IsInstanceValid(target)) { target.QueueFree(); }

// Good: Pattern matching for state.
switch (Velocity) { case { X: > 0 }: /* ... */ break; }

// Good: Unsubscribe in _ExitTree to prevent leaks.
public override void _ExitTree() { _healthComponent.HealthChanged -= OnHealthChanged; }

// Bad: Connect() in C# (use C# events instead).
_healthComponent.Connect("HealthChanged", new Callable(this, "OnHealthChanged"));

// Bad: GetNode<T>() when [Export] is available.
private HealthComponent _health = GetNode<HealthComponent>("HealthComponent");

// Bad: Tabs in C# (use 4 spaces).
```
