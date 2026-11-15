---
name: csharp-guidelines
description: C# language coding conventions, naming rules, comment style, default libraries, and best practices. This skill overrides external style guides where it defines rules. Load when writing or reviewing C# code.
---

# C# Language Guidelines

## Style Priority (Read First)

When writing or reviewing C# in a project that uses this skill:

1. **This skill wins for code style** — naming, comments, namespace layout, default libraries, build/test defaults, and any other rule stated in this file take precedence over external guides and over habits from other codebases (Microsoft C# Coding Conventions, .NET Runtime style, team wiki, etc.).
2. **External references fill gaps only** — use the links below when this skill is **silent** on a topic (e.g. Roslyn internals, MSBuild details, unsafe code). Do not replace or weaken an explicit rule here with a conflicting external convention.
3. **On conflict** — if an external document disagrees with this skill (e.g. `s_camelCase` static fields, `m_` member prefixes, `GetXxx()` getters), **follow this skill** for project code.

## Core References

Use these when this skill does not cover the topic:

- [Microsoft C# Coding Conventions](https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions) — official C# style
- [.NET Design Guidelines](https://learn.microsoft.com/en-us/dotnet/standard/design-guidelines/) — framework design rules
- [C# Language Reference](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/) — authoritative language spec
- [Framework Design Guidelines (3rd ed.)](https://www.informit.com/store/framework-design-guidelines-conventions-idioms-and-9780135896464) — classic reference (paid)

## C# Version Detection

- **Check the project files first** — read `*.csproj` or `Directory.Build.props` for `TargetFramework` (e.g. `net8.0`) and `LangVersion` before writing code. Match the project's target framework; do not use features it cannot compile.
- **Unity caveat**: Unity projects often lag behind the latest C# language version. Verify the Unity editor version and scripting backend before using records, primary constructors, file-scoped namespaces, `required`, collection expressions, or other newer features.
- **Prefer modern features** that simplify code, when the version allows:
  - **C# 9**: records, `init` accessors, top-level statements, pattern matching enhancements, target-typed `new`.
  - **C# 10**: file-scoped namespaces, global usings, constant interpolated strings, record structs.
  - **C# 11**: raw string literals, required members, generic attributes, UTF-8 string literals.
  - **C# 12**: primary constructors, collection expressions, inline arrays, `nameof` parameter scopes.
  - **C# 13**: `params` collections, `field` keyword (preview), partial properties, new lock object.
- **Replace legacy idioms** — `var` where the type is obvious, pattern matching over `is` + cast, `switch` expressions over imperative `switch`, `??` / `?.` over null checks, file-scoped namespaces, expression-bodied members for simple bodies.

## Naming Conventions

### Naming Table

| Element | Convention | Example |
| --- | --- | --- |
| **Namespaces** | PascalCase | `namespace Game.Combat` |
| **Classes / Structs / Records** | PascalCase | `public class UserManager` |
| **Interfaces** | `I` + PascalCase | `public interface IDamageable` |
| **Methods** | PascalCase | `public void ProcessData()` |
| **Properties (public / protected / protected internal)** | camelCase | `public int maxItems { get; set; }` |
| **Properties (private)** | `_camelCase` | `private int _itemCount { get; set; }` |
| **Events** | PascalCase, prefer `On` prefix | `public event Action OnDoorOpened` |
| **Fields (public / protected / protected internal)** | camelCase | `public int maxItems` |
| **Fields (private)** | `_camelCase` | `private int _itemCount` |
| **Local variables** | camelCase | `var itemCount = 0` |
| **Parameters** | camelCase | `void SetName(string name)` |
| **Constants** | `CONSTANT_CASE` | `public const int MAX_BUFFER_SIZE = 1024` |
| **Static fields** | PascalCase | `private static int EnemyCount` |
| **Static readonly fields** | PascalCase | `public static readonly TimeSpan DefaultTimeout` |
| **Enum types** | PascalCase | `public enum Status` |
| **Enum members** | PascalCase | `Success, NotFound, Pending` |
| **Type parameters** | Single uppercase letter or descriptive `T` prefix | `T`, `TKey`, `TValue`, `TContext` |
| **Generic constraints** | Descriptive | `where T : class, IComparable<T>` |

Properties follow the same visibility-based naming as fields: public, protected, and protected internal properties use camelCase; private properties use `_camelCase`. Converting a field to a property does not change its naming convention. Methods and events remain PascalCase.

### Semantic Naming Rules

Format is not enough — a name must convey **meaning and intent**:

- **Booleans** (variables and predicate methods) read as a yes/no question: prefix with `Is` / `Has` / `Can` / `Should` / `Use`.
  - `IsOpen`, `HasNext`, `CanRetry`, `ShouldFlush`, `UseCache`
  - `bool IsValid()`, `bool HasCapacity()`
  - Avoid negated names — prefer `IsReady` over `IsNotReady` (double negatives in conditions are error-prone).
- **Action methods** are verbs or verb-phrases — `Connect()`, `ParseHeader()`, `FlushBuffer()`, `ComputeHash()`.
- **Getters / setters**: prefer properties — `name { get; set; }`. For computed values use a get-only property: `public int count => _items.Count;`. Unity code often uses `GetXxx()` / `SetXxx()` methods for runtime-facing values; use whichever pattern matches the surrounding codebase, but do not wrap a trivial property with a separate `GetXxx()` method.
- **Factory methods**: `CreateXxx()` / `NewXxx()` — mirroring `new` semantics, e.g. `CreateUser()`, `NewConnectionPool()`.
- **Counts / sizes / indices**: `xxxCount` (or `numXxx`) for counts, `xxxSize` for byte/element sizes, `xxxIdx` for indices.
- **Units in the name** whenever a bare number is ambiguous — `timeoutMs`, `sizeBytes`, `delaySeconds`, `widthPx`.
- **Scope governs length** — short names in tight scopes (`i`, `v`, `ctx`, `err`, `buf`), descriptive names for wider scope (`connectionPool`, `maxConcurrentRequests`).
- **Abbreviations**: spell words out except well-established ones — `id`, `url`, `http`, `db`, `io`, `ctx`, `msg`, `buf`, `src`, `dst`.
- **Avoid Hungarian notation or scope prefixes** — no `m_`, `s_`, `g_`, `p`, `k_` prefixes. A single `_` for private instance fields is the only allowed prefix.

## Unity Serialization Conventions

These rules apply when writing `MonoBehaviour` / `ScriptableObject` classes and other Unity-serialized types:

- **Prefer `[SerializeField] private` over public fields** when exposing values to the Inspector. This keeps implementation details encapsulated.
  - `[SerializeField] private float _moveSpeed = 5f;`
- **Private serialized fields keep `_camelCase`** so they read naturally next to other private fields.
- **Public fields are acceptable** for simple Inspector-tweakable values that need no encapsulation; use `camelCase`.
  - `public int health = 100;`
- **Expose read-only values through camelCase properties** rather than public fields.
  - `public float moveSpeed => _moveSpeed;`
- **Avoid serializing complex logic**. Serialized fields should be data, not behavior.

## Code Layout and Organization

### File Structure

- **One primary type per file**, the file named after the type in PascalCase (`UserManager.cs` → `UserManager`). Small, tightly-coupled helpers may share the file.
- **Prefer file-scoped namespaces** (`namespace Game.Combat;`) on a single line. Use block namespaces only when a file genuinely needs multiple namespaces.
- **Namespaces reflect logical boundaries**, not the physical folder hierarchy. In Unity projects, do not require namespaces to match the `Assets/Scripts/...` folder structure; disable `IDE0130` / `dotnet_style_namespace_match_folder`.
  - Good: `namespace Metroidvania.Core;`
  - Avoid: `namespace Assets.Scripts.Core;`
- **Keep partial classes cohesive** — split partials by responsibility (e.g. generated vs. hand-authored), not arbitrarily.

### File Order (Top → Bottom)

1. `using` statements (System first, then Microsoft/Unity, then third-party, then project; alphabetized within groups)
2. File-scoped `namespace` declaration
3. XML doc comment for the type (`///`)
4. Constants / static fields
5. Nested types (enums, structs) that belong to the primary type
6. `[SerializeField]` private fields (Unity)
7. Other private / protected fields
8. Constructor(s) / primary constructor
9. Properties
10. Public methods
11. Unity messages (`Awake`, `Start`, `Update`, etc.) — keep together and in lifecycle order
12. Protected / internal methods
13. Private methods
14. Nested classes (if any)

### Class Member Order

Order by **visibility first**, then by kind:

1. `public` → `protected` / `internal` → `private`
2. Within each access section, in this order:
   1. Constants and static fields
   2. Nested types and type aliases
   3. Instance fields
   4. Constructors
   5. Properties
   6. Methods (keep related methods grouped)

### Formatting Rules

- **Indentation**: 4 spaces. Never tabs.
- **Brace style**: 1TBS style — opening brace on the same line as the declaration. This project uses 1TBS even though Microsoft samples often show Allman; be consistent within the codebase.
- **Line length**: 120 characters maximum.
- **Use `var`** when the type is obvious from the right-hand side. Use explicit types when the type improves readability or is not obvious.
- **Expression-bodied members are allowed** for simple one-liners: `public int count => _items.Count;`.
- **Prefer `is` patterns and `switch` expressions** over casts and imperative `switch`.
- **Use `nameof`** instead of string literals for member names.
- **String interpolation** (`$"..."`) over `string.Format` or concatenation.

## Comment Conventions

### What Must Be Documented

**Mandatory** — these MUST carry a `///` XML doc comment immediately above the declaration:

- **All public / protected types and members** — classes, structs, records, interfaces, enums, methods, properties, events, constants.
- **Public constructors** — state what object state is established.
- **Enums and their values** — the meaning of each variant.
- **Non-trivial data members** that carry a non-obvious invariant, unit, or lifetime requirement.
- **Every source file** gets a one-line `//` summary at the top (after any license header).

**Optional / discouraged**:

- Trivial private helpers, obvious getters/setters, and self-documenting code need no comment.
- Never write a comment that merely restates the code (`// increment i`).
- Comment the **why**, not the **what** — and prefer renaming over explaining a poor name.
- Use `// TODO(name):` / `// FIXME(name):` with an owner for deferred work.

### General Rules

- **Use `///` XML doc comments** for public API documentation. Use `//` for inline and implementation comments. Do **not** use `/* */` block comments anywhere in project C# code.
- Write documentation as **plain sentences** — do **not** use metadata prefixes like `brief:`, `details:`, or `see:` on comment lines. Inside XML docs, prefer minimal tags (`<summary>`, `<param>`, `<returns>`, `<exception>`); avoid bloated XML where plain text suffices.
- Write multi-line documentation as **consecutive `///` lines**.
- Prefer **English** for all comments and docstrings.
- **No decorative section banners** — do not use lines like `// ---------- Section ----------` or `// ==== Foo ====`. Use a normal `//` sentence if a boundary needs explaining, or let the code structure speak for itself.

### File Header

Place **one plain summary line** at the top of every `.cs` file (after a license block if present):

```csharp
// HTTP client for synchronous and async requests.
```

### Type Documentation

```csharp
/// <summary>
/// Owns a pool of reusable TCP connections to upstream hosts.
/// Connections are acquired via Acquire() and must be returned with Release().
/// </summary>
public class ConnectionPool {
    // ...
}
```

### Method Documentation

```csharp
/// <summary>
/// Sends an HTTP GET request and returns the response body on success.
/// </summary>
/// <param name="url">Absolute or root-relative URL; must be non-empty.</param>
/// <param name="timeoutMs">Maximum wait per attempt; must be positive.</param>
/// <returns>Response body bytes; empty if the server returns no body.</returns>
/// <exception cref="ArgumentException">Thrown when url is null or empty.</exception>
public byte[] Get(string url, int timeoutMs) {
    // ...
}
```

## Decomposition Granularity

- **Namespace / project**: one cohesive responsibility / bounded context. Avoid `Utilities`, `Common`, `Helpers` as dumping grounds.
- **File**: under **800 lines** (global rule). Split when a file accumulates unrelated concerns — not merely when it grows.
- **Class / record / struct**: a single responsibility. Keep the public interface minimal (Minimal Export Principle) — roughly **≤ 10–15 public members**. Prefer **composition over deep inheritance**.
- **Method**: under **50 lines** (global rule), at a **single level of abstraction**, with **≤ 4 parameters** — bundle more into a small record or class.
- **Static method over instance method** when it needs no instance state; **extension method** when it logically belongs to an external type but is project-specific.

## Type System: Records, Classes, Structs

- **Use `record`** for immutable data-centric types with value semantics: `public record User(string Name, string Email);`.
- **Use `record class`** when you need reference semantics with record features; **use `record struct`** for small immutable value types.
- **Use `class`** for mutable entities, services, managers, and anything with identity or lifecycle.
- **Use `struct`** only for small, immutable value types that are frequently copied and do not box. Avoid mutable structs.
- **Prefer `init` accessors** for immutable object initialization: `public string Name { get; init; }`.
- **Prefer primary constructors** (C# 12+) for simple dependency injection and record shorthand.

In Unity projects, `record`, `init`, and primary constructors are only available when the scripting profile supports them. Most Unity code still relies on plain `class` / `struct`; do not force record-style patterns into older Unity projects.

## Generics

- **Constrain type parameters** with `where` clauses rather than runtime casts.
- **Name type parameters descriptively** when their role is not obvious: `TKey`, `TValue`, `TContext`. Single letters (`T`, `U`) are fine for truly generic helpers.
- **Avoid unconstrained generic code** when a specific interface constraint expresses intent more clearly.
- **Document type parameter requirements** with a `///` line when non-obvious.

## Resource Management & IDisposable

- **Deterministic cleanup with `IDisposable`** — every resource (file, socket, connection, handle, subscription) that holds unmanaged or scarce resources must implement `Dispose()` or be wrapped in `using`.
- **Use `using` declarations** for deterministic scope-based disposal:
  ```csharp
  await using var connection = await factory.OpenAsync();
  ```
- **Avoid finalizers** unless you directly hold unmanaged resources. If needed, implement the full dispose pattern with `Dispose(bool)`.
- **Create async disposables** (`IAsyncDisposable`) when cleanup involves I/O.
- **Do not rely on the GC for timely cleanup** of unmanaged or shared resources.

## Nullable Reference Types

- **Enable nullable reference types** (`<Nullable>enable</Nullable>`) for new projects. Treat compiler warnings as errors in CI.
- **Express nullability in the type system** — `string?` for maybe-null, `string` for non-null.
- **Use null-forgiving operator (`!`) sparingly** — it is a lie to the compiler; justify every use with a comment.
- **Prefer `??`, `?.`, `??=`, and pattern matching** over manual null checks.
- **Validate nulls at API boundaries** and throw `ArgumentNullException` for required reference parameters.

## Async & Await

- **Use `async`/`await` for I/O-bound and asynchronous work**. Avoid blocking calls (`.Result`, `.Wait()`, `.GetAwaiter().GetResult()`) except at a deliberate application boundary.
- **Return `Task` / `Task<T>` / `ValueTask<T>`** from async methods. Use `ValueTask<T>` only when the hot path is synchronous and allocation matters.
- **Name async methods with an `Async` suffix** — `GetUserAsync()`, `SaveAsync()`.
- **Propagate `CancellationToken`** through the call stack; do not swallow or ignore it.
- **Avoid `async void`** except for event handlers; always prefer `async Task`.
- **ConfigureAwait**: use `ConfigureAwait(false)` in library code; omit it in UI / top-level application code where synchronization context matters.

## Error Handling

- **Exceptions for exceptional conditions** — use exceptions for programmer errors and unexpected failures, not for normal control flow.
- **Be specific** — throw and catch specific exception types (`ArgumentException`, `InvalidOperationException`, `IOException`), never bare `catch` unless logging/rethrowing at a top-level boundary.
- **Use `ArgumentNullException.ThrowIfNull`** (or `ArgumentException` helpers) for parameter validation.
- **Preserve stack traces** when rethrowing: use `throw;`, not `throw ex;`.
- **Result types for expected failures** — for recoverable, business-logic outcomes (validation, parsing), consider a `Result<T, TError>` type instead of exceptions.
- **Never swallow exceptions silently** — at minimum log them.
- **`Debug.Assert`** for internal invariants only; never for user-facing validation.

## LINQ & Functional Style

- **Use LINQ for declarative transformations** where it improves readability: `Select`, `Where`, `OrderBy`, `GroupBy`, `ToList`, `ToDictionary`.
- **Avoid LINQ on hot paths** where allocations and delegate overhead matter — prefer explicit loops.
- **Materialize once** — call `ToList()` / `ToArray()` when you will enumerate multiple times; otherwise defer with `IEnumerable<T>`.
- **Prefer method syntax** over query syntax unless the query is genuinely clearer in SQL-like form.

## Pattern Matching

- **Prefer pattern matching** over `is` + cast chains:
  ```csharp
  if (shape is Circle c) { ... }
  ```
- **Use `switch` expressions** for mapping values:
  ```csharp
  var color = status switch
  {
      Status.Ok => Colors.Green,
      Status.Warning => Colors.Yellow,
      Status.Error => Colors.Red,
      _ => Colors.Gray
  };
  ```
- **Use list patterns and relational patterns** (C# 11+) when they clarify intent.

## Immutability

- **Favor immutability by default** for data carriers and value types.
- Use `init`-only properties, `readonly` fields, and records to reduce mutable surface area.
- **Mark fields `readonly`** when they are assigned only in constructors.
- **Avoid mutable static state**; pass dependencies explicitly.

## Dependency Injection

- **Prefer constructor injection** over service locator or static access.
- **Keep constructors simple** — only assign injected dependencies; avoid heavy work in constructors.
- **Use interfaces for seams** — `ILogger<T>`, `IUserStore`, `IEventBus`.
- **Avoid `new`-ing services directly** in business logic; request them through the constructor.

## Concurrency

- **Use `async`/`await` and `Task` for concurrency**, not raw `Thread` unless you truly need a dedicated OS thread.
- **Protect shared mutable state** with `lock` / `SemaphoreSlim` / `ReaderWriterLockSlim`. Use `lock` with a private readonly object or, preferably, immutable data structures.
- **Prefer immutable collections** (`ImmutableList<T>`, `ImmutableDictionary<K, V>`) or `ConcurrentDictionary` for shared state.
- **Use `Channel<T>`** for producer/consumer scenarios.
- **Document thread-safety** in XML docs for every public type that is or is not safe for concurrent use.
- **Avoid `lock (this)`** — use a private `readonly object _lock = new();`.

## Performance & Memory

Optimize for clarity first; reach for these only on a measured-hot path:

- **Measure before optimizing** — use `BenchmarkDotNet` or a profiler; do not guess.
- **Avoid allocations in hot loops** — pre-size collections, reuse buffers, avoid LINQ and closures on hot paths.
- **ValueTask / IAsyncEnumerable** for streaming or allocation-sensitive async code.
- **`Span<T>` / `Memory<T>` / `ReadOnlySpan<T>`** for low-allocation buffer slicing and parsing.
- **Prefer `struct` only when profiling shows it helps** — premature struct optimization causes boxing and copying pain.
- **`ArrayPool<T>.Shared`** for temporary buffers.
- **Object pooling** for frequently created short-lived objects.

## Tooling & Diagnostics

- **Formatting**: use `dotnet format` or an EditorConfig. Never hand-format C# code.
- **Linting / analyzers**: enable the .NET SDK analyzers and StyleCop / Roslyn analyzers configured in `.editorconfig` or `Directory.Build.props`.
- **Warnings**: build with warnings as errors in CI (`<TreatWarningsAsErrors>true</TreatWarningsAsErrors>`).
- **Nullable reference types**: enable and enforce in CI for modern .NET projects. In Unity, enable only when the editor / player profile supports it and the serializer handles it cleanly.
- **Static analysis**: run static analysis tools (e.g. Sonar, ReSharper, CodeQL) where available.

## Default Libraries and Frameworks

**Library Selection Priority**:
1. **.NET Standard Library / Base Class Library** (first choice)
2. **Well-established Microsoft extensions** (second choice)
3. **Well-established third-party libraries** (third choice)

**Recommended Defaults**:

| Category | First Choice | Notes |
| --- | --- | --- |
| **HTTP Client** | `System.Net.Http` | `HttpClient` via `IHttpClientFactory` |
| **HTTP Server** | ASP.NET Core Minimal APIs / MVC | Match project template |
| **JSON** | `System.Text.Json` | Faster and allocation-friendlier than Newtonsoft.Json. In Unity, Newtonsoft.Json is bundled and commonly used; `System.Text.Json` may not be available depending on profile. |
| **Configuration** | `Microsoft.Extensions.Configuration` | JSON, env vars, command line |
| **Dependency Injection** | `Microsoft.Extensions.DependencyInjection` | Default for .NET |
| **Logging** | `Microsoft.Extensions.Logging` | Use `ILogger<T>` |
| **Testing** | xUnit or NUnit | xUnit preferred for new projects. In Unity, use the Unity Test Framework (NUnit-based). |
| **Mocking** | NSubstitute or Moq | NSubstitute has cleaner syntax |
| **Assertions** | FluentAssertions | Readable assertion library |
| **Object Mapping** | Manual mapping or Mapperly | Avoid heavy reflection-based mappers |
| **Validation** | `System.ComponentModel.DataAnnotations` or FluentValidation | Match project |
| **ORM** | EF Core | For SQL; Dapper for raw performance |
| **Caching** | `Microsoft.Extensions.Caching.Memory` | In-memory; Redis via `IDistributedCache` |
| **CLI** | `System.CommandLine` | Modern parser |
| **Serialization** | `System.Text.Json` | Source generators for AOT scenarios. In Unity, prefer Newtonsoft.Json or Unity's own serializers. |

### Unity Projects

For Unity C# code, prefer libraries that ship with or are commonly adopted by the engine:

- **JSON**: `Newtonsoft.Json` (bundled with Unity) is the safe default.
- **Testing**: Unity Test Framework (NUnit-based) for play-mode and edit-mode tests.
- **Async / coroutines**: coroutines are the traditional Unity pattern; `async`/`await` works but often needs `UniTask` or careful synchronization-context handling.
- **DI / logging**: use Unity-specific solutions or lightweight custom abstractions rather than `Microsoft.Extensions.*` unless you are targeting a non-Unity assembly.

## Testing

- **One test class per unit under test**, named after it; mirror the source tree under `tests/`.
- **Name tests by behavior, not by method** — `Connect_FailsOnBadHandshake`, not `TestConnect`.
- **Use `async Task` test methods** for async code; avoid `async void`.
- **Cover the contract and the edges** (empty, boundary, error paths), not just the happy path; keep one logical focus per test case.
- **No real network / disk / clock in unit tests** — inject seams or fakes so tests stay deterministic and fast.
- **Tests are first-class code**: same naming, layout, comment, and review bar as production code.
- **Run tests in CI** with warnings-as-errors and nullable reference types enabled.

In Unity projects, use the **Unity Test Framework** (NUnit-based) for edit-mode and play-mode tests; the xUnit / Moq ecosystem applies only to non-Unity test assemblies.

## C#-Specific Best Practices

```csharp
// Controls player movement and health.

using UnityEngine;

namespace Game.Player;

/// <summary>
/// Drives player movement and tracks health for a single actor.
/// </summary>
public class PlayerController : MonoBehaviour {
    public const int MAX_HEALTH = 100;
    private static int PlayerCount;

    [SerializeField] private float _moveSpeed = 5f;
    [SerializeField] private int _maxHealth = MAX_HEALTH;

    private int _currentHealth;
    private Vector3 _velocity;

    public int currentHealth => _currentHealth;

    private void Awake() {
        PlayerCount++;
        _currentHealth = _maxHealth;
    }

    private void Update() {
        float horizontal = Input.GetAxis("Horizontal");
        float vertical = Input.GetAxis("Vertical");
        _velocity = new Vector3(horizontal, 0f, vertical).normalized * _moveSpeed;
    }

    private void FixedUpdate() {
        transform.position += _velocity * Time.fixedDeltaTime;
    }

    public void TakeDamage(int amount) {
        _currentHealth = Mathf.Max(0, _currentHealth - amount);
    }

    public void SetMaxHealth(int maxHealth) {
        _maxHealth = Mathf.Clamp(maxHealth, 1, MAX_HEALTH);
        _currentHealth = Mathf.Min(_currentHealth, _maxHealth);
    }
}

// Good: enum with PascalCase members
public enum PlayerState {
    Idle,
    Moving,
    Dead
}

// Good: expression-bodied member for trivial computed properties
public class HealthBar : MonoBehaviour {
    [SerializeField] private PlayerController _player;

    public float fillAmount => (float)_player.currentHealth / PlayerController.MAX_HEALTH;
}
```
