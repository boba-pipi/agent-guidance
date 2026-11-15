---
name: cpp-guidelines
description: C++ language coding conventions, naming rules, comment style, default libraries, and best practices. This skill overrides external style guides where it defines rules. Load when writing or reviewing C++ code.
---

# C++ Language Guidelines

## Style priority (read first)

When writing or reviewing C++ in a project that uses this skill:

1. **This skill wins for code style** — naming, comments, enums, default libraries, build/test defaults, and any other rule stated in this file take precedence over external guides and over habits from other codebases (Google C++ Style, LLVM, team wiki, etc.).
2. **External references fill gaps only** — use the links below when this skill is **silent** on a topic (e.g. object lifetimes, const correctness, standard library API details). Do not replace or weaken an explicit rule here with a conflicting external convention.
3. **On conflict** — if an external document disagrees with this skill (e.g. `snake_case` namespaces, `/* */` documentation, plain `enum`), **follow this skill** for project code.

## Core References

Use these when this skill does not cover the topic:

- [C++ Core Guidelines](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines) — general best practices (only where not overridden above)
- [cppreference.com](https://en.cppreference.com/w/) — language and standard library reference

> **Note**: *Effective Modern C++*, *Effective C++*, and *More Effective C++* by Scott Meyers are classic references but require paid subscriptions. Prefer this skill for style; use Core Guidelines / cppreference for gaps.

## Language Standard

- **Detect the standard first** — check `CMakeLists.txt` for `CMAKE_CXX_STANDARD` / `target_compile_features(... cxx_std_NN)` (or the `-std=` flag) before writing code. Match the project's standard; do not use features it cannot compile.
- **Prefer modern features** that simplify code, when the standard allows:
  - **C++17**: structured bindings, `if constexpr`, `std::optional`, `std::variant`, `std::string_view`, `std::filesystem`, fold expressions, `[[nodiscard]]` / `[[maybe_unused]]`.
  - **C++20**: concepts, ranges (`std::ranges` / `std::views`), `std::span`, `<format>`, designated initializers, `consteval` / `constinit`, three-way comparison (`<=>`), `std::jthread`.
  - **C++23**: `std::expected`, `std::print` / `std::println`, `std::mdspan`, deducing `this`.
- **Replace legacy idioms** — `enum class` over `enum`, `nullptr` over `NULL` / `0`, `using` aliases over `typedef`, range-based `for` over index loops, `<random>` over `rand()`, RAII over manual `new` / `delete`.

## Enumerations

- **Use `enum class`**: Always prefer `enum class` over plain `enum` for type safety
  - Example: `enum class Status { success, failure };`

## Naming Conventions

**CamelCase Naming Convention**:

| Element                      | Convention                      | Example                                        |
| ---------------------------- | ------------------------------- | ---------------------------------------------- |
| **Classes**                  | UpperCamelCase                  | `UserManager`, `HttpClient`                    |
| **Namespaces**               | UpperCamelCase (same as classes)| `namespace Http`, `namespace Filesystem`       |
| **Constants**                | lowerCamelCase                  | `maxRetries`, `defaultTimeout`                 |
| **Variables**                | lowerCamelCase                  | `userName`, `connectionPool`                   |
| **Functions**                | lowerCamelCase                  | `processData()`, `validateInput()`             |
| **Macros**                   | UPPER_SNAKE_CASE                | `MAX_BUFFER_SIZE`, `DEBUG_MODE`                |
| **Enum Class Types**         | UpperCamelCase                  | `enum class Status`, `enum class ErrorCode`    |
| **Enum Values**              | lowerCamelCase                  | `Status::success`, `ErrorCode::notFound`       |
| **Type Template Parameters** | UpperCamelCase (like classes)   | `template<typename T, typename U>`             |
| **Non-Type Templates**       | lowerCamelCase (like constants) | `template<int maxSize, bool enableCache>`      |

Nested namespaces use the same rule: `namespace Http::Internal { ... }` or nested `namespace Http { namespace Internal { } }`.

### Semantic Naming Rules

Format is not enough — a name must convey **meaning and intent**:

- **Booleans** (variables and predicate functions) read as a yes/no question: prefix with `is` / `has` / `can` / `should` / `use`.
  - `isOpen`, `hasNext`, `canRetry`, `shouldFlush`, `useCache`
  - `bool isValid() const;`, `bool hasCapacity() const;`
  - Avoid negated names — prefer `isReady` over `isNotReady` (double negatives in conditions are error-prone).
- **Action functions** are verbs or verb-phrases — `connect()`, `parseHeader()`, `flushBuffer()`, `computeHash()`.
- **Getters / setters**: the getter is a noun, the mutator takes a `set` prefix — `name()` / `setName()`. Do **not** add a `get` prefix and do **not** mix `getName()` with `name()`; this project uses the no-`get` form.
- **Counts / sizes / indices**: `xxxCount` (or `numXxx`) for counts, `xxxSize` for byte/element sizes, `xxxIdx` for indices.
- **Units in the name** whenever a bare number is ambiguous — `timeoutMs`, `sizeBytes`, `delaySeconds`, `widthPx`.
- **Convey ownership through the type, not the name** — use `std::unique_ptr` / `std::shared_ptr` / `std::span` / references. Do **not** use Hungarian or scope prefixes (`pXxx`, `m_xxx`, `g_xxx`) or trailing-underscore member tags; a plain lowerCamelCase member name is enough.
- **Factory functions**: `makeXxx` / `createXxx`, mirroring `std::make_unique`.
- **Scope governs length** — short names in tight scopes (`i`, `it`, `ctx`), descriptive names for wider scope (`connectionPool`, `maxConcurrentRequests`).
- **Abbreviations**: spell words out except well-established ones — `id`, `url`, `http`, `db`, `io`, `ctx`.

## File Layout and Organization

### File split (header / source)

- **One primary type per `.h` / `.cpp` pair**, the file named after the type in UpperCamelCase (`HttpClient` → `HttpClient.h` / `HttpClient.cpp`). Small, tightly-coupled helpers may share the file.
- Declarations live in the header; non-template definitions live in the `.cpp`. Small templates and `constexpr` helpers may stay header-only.

### Header file order (top → bottom)

1. `#pragma once`
2. The one-line `//` file summary (see Comment Conventions).
3. Includes, grouped with a blank line between groups, alphabetized within each group:
   1. C++ standard library (`<string>`, `<vector>`, …)
   2. Third-party libraries (Boost, SDL, …)
   3. This project's headers
   (In the `.cpp`, the matching header comes **first**, before all the groups above.)
4. Forward declarations
5. `namespace` open (with its one-line `//` doc)
6. File-scope constants, type aliases, and enums
7. Class / function declarations
8. `namespace` close (`}  // namespace Name`)

### Class member order

Order by **visibility first** (what a reader needs is at the top), then by kind:

1. `public:` → `protected:` → `private:`
2. Within each access section, in this order:
   1. Nested types and type aliases
   2. Static constants
   3. Constructors, then destructor
   4. Operators
   5. Other methods (keep related methods grouped)
   6. **Data members last**
- In the `.cpp`, define members in the **same order** they were declared in the header.

## Comment Conventions

### What must be documented

**Mandatory** — these MUST carry a `//` doc comment immediately above the declaration:

- Public / protected **classes and structs** — purpose, key invariants, ownership, and thread-safety expectations.
- Public / protected **methods** and free **functions** — behavior, non-obvious parameters, return value, and error/exception/`expected` outcomes plus any pre/post-conditions.
- Exported **constants** and **enums**, plus any enum value whose meaning is not self-evident.
- Exported **macros** and **templates** — document the template's type requirements / constraints.
- **Data members** that carry a non-obvious invariant, unit, or lifetime requirement.
- Every **file** and every **namespace** (the one-line summary described below).

**Optional / discouraged**:

- Trivial private helpers, obvious getters/setters, and self-documenting code need no comment.
- Never write a comment that merely restates the code (`// increment i`).
- Comment the **why**, not the **what** — and prefer renaming over explaining a poor name.
- Use `// TODO(name):` / `// FIXME(name):` with an owner for deferred work.

### General rules

- **Use `//` only** for all comments (single-line and multi-line documentation). Do **not** use `/* */` block comments anywhere in project C++ code.
- Write documentation as **plain `//` sentences** — do **not** use metadata prefixes like `file:`, `brief:`, `details:`, or `see:` on comment lines.
- Write multi-line documentation as **consecutive `//` lines** (one thought per line when it helps readability).
- Prefer **English** for public API and shared modules; match the surrounding file if the project is consistently localized.
- Comment **why** and **non-obvious contracts**; avoid restating what the code already says (`i++` → `// increment i` is useless).
- Keep line comments at **end of line** only for very short clarifications; put file/class/function docs **above** the declaration.
- **No decorative section banners** — do not use lines like `// ---------- Section ----------`, `// ---- Foo ----`, or `// ─── Bar ───`. Use a normal `//` sentence if a boundary needs explaining, or let the code structure speak for itself.

### File header

Place **one plain summary line** at the top of every `.h` / `.hpp` / `.cpp` (after a license block if present):

```cpp
// HTTP client for synchronous and async requests.
```

For implementation files:

```cpp
// Implementation of HttpClient.
```

Do **not** repeat the path (`// file: HttpClient.hpp`) or use `// brief:` — the filename already identifies the unit.

### Namespace documentation

Place immediately **before** the namespace (or the opening of a nested namespace):

```cpp
// HTTP protocol clients, request builders, and response parsers.
namespace Http {

// Internal helpers not part of the public API.
namespace Internal {

}  // namespace Internal
}  // namespace Http
```

Always close nested namespaces with `// namespace Name` on the closing brace.

### Class / struct documentation

Place immediately **before** the type. Document invariants and ownership in plain sentences:

```cpp
// Owns a pool of reusable TCP connections to upstream hosts.
// Connections are lent via acquire() and must be returned with release().
// Destruction waits for all lent connections to be returned or times out per pool policy.
class ConnectionPool {
public:
    // ...
};
```

For trivial typedefs or type aliases, a single `//` line is enough.

### Function documentation

Place immediately **before** the declaration in the header (repeat in `.cpp` only if behavior differs from the header contract).

Use plain sentences for the summary. For parameters and return values you may use explicit labels (optional):

```cpp
// Sends an HTTP GET and returns the response body on success.
// param url: Absolute or root-relative URL; must be non-empty.
// param timeoutMs: Maximum wait per attempt; must be > 0.
// returns: Response body bytes; empty if the server returns no body.
std::vector<std::byte> get(const std::string& url, int timeoutMs);
```

- **Constructors**: state what object state is established; document meaningful arguments.
- **Destructors**: document side effects only when non-obvious (e.g. flushes, joins threads).
- **Templates**: document type requirements in a plain `//` line (`T` must be MoveConstructible, etc.).

### Variable and member documentation

- **Data members** (especially public or protected): one plain `//` line above the member, or end-of-line `//` only if the name is self-explanatory and the line stays short.

```cpp
class DatabaseConnection {
    // Upper bound on simultaneous open connections.
    int maxPoolSize = 8;

    // DSN or connection URI passed to the driver.
    std::string connectionString;

public:
    void connect();
};
```

- **Local variables**: comment only when the name cannot carry the intent (algorithm steps, units, magic indices). Prefer renaming over commenting.
- **Constants / constexpr**: a plain `//` line above, or `//` at end of line for enum-like locals.

```cpp
// Default number of retry attempts for idempotent requests.
constexpr int defaultMaxRetries = 3;
```

### Inline and implementation comments

- Use `//` inside function bodies for non-obvious steps, invariants, or TODO/FIXME:

```cpp
// TODO(username): add cancellation token support
// FIXME: handle partial writes on Windows
```

- Do not use `/* */` for commented-out code; delete dead code or guard with `#if 0` only when a project already standardizes that (prefer deletion).

## Decomposition Granularity

- **Module**: one cohesive responsibility / bounded subsystem. Map a module to a `namespace` **and** a directory.
- **File**: under **800 lines** (global rule). Split when a header accumulates unrelated concerns — not merely when it grows.
- **Class**: a single responsibility. If groups of methods touch **disjoint** subsets of the data members, that is a signal to split the class. Keep the public interface minimal (Minimal Export Principle) — roughly **≤ 10–15 public methods**. Prefer **composition over deep inheritance**.
- **Function**: under **50 lines** (global rule), at a **single level of abstraction**, with **≤ 4 parameters** — bundle more into a small struct (this also defends against argument-order mistakes).
- **Free function over member function** when it needs no private access (Core Guidelines C.4 / C.5) — this shrinks the class interface and improves testability.

## Resource Management & Ownership

- **RAII always** — every resource (memory, file, socket, lock, handle) is owned by an object whose destructor releases it. Never hand-pair `new` / `delete` or `malloc` / `free`.
- **Express ownership in the type**:
  - `std::unique_ptr<T>` — single, exclusive owner (the default for heap objects).
  - `std::shared_ptr<T>` — genuinely shared ownership only; it is not free (atomic refcount). Break cycles with `std::weak_ptr`.
  - raw `T*` / `T&` — **non-owning** observation, never deletes.
  - `std::span<T>` / `std::string_view` — non-owning view over a contiguous range / string; must not outlive the source.
- **Create with `std::make_unique` / `std::make_shared`**, never a bare `new`.
- **Rule of Zero** — design so the compiler-generated special members suffice; let members (smart pointers, containers) manage resources. Write none of the five.
- **Rule of Five** — if you must hand-write one of {destructor, copy ctor, copy assign, move ctor, move assign}, declare all five (`= default` / `= delete` the rest). Mark move operations `noexcept`.
- **Moving**: use `std::move` to transfer ownership of a named object; do **not** `std::move` a local you are returning — it blocks NRVO.

## Move Semantics & Value Categories

- **Move transfers, copy shares** — `std::move` only casts to an rvalue so a resource *can* be stolen; it does not itself move anything. After a move the source is valid-but-unspecified — only reassign or destroy it.
- **Do not `std::move` a returned local** — it suppresses NRVO / copy-elision and is usually slower. Write `return obj;`, not `return std::move(obj);`.
- **Take sinks by value, then move** — one `T param` + `member = std::move(param)` overload serves both lvalue and rvalue callers (see Parameter Passing).
- **Forwarding** — in a template taking `T&&`, use `std::forward<T>(x)` to preserve the caller's value category; reserve `std::move` for concrete (non-deduced) types.
- **Mark move ctor / move assign `noexcept`** — otherwise containers fall back to copying on reallocation.
- **`= default` the move operations** when members are movable; the Rule of Zero already gives you correct moves for free.

## Const Correctness

- Mark member functions `const` whenever they do not modify observable state — this is the default; non-`const` is the exception.
- Pass read-only parameters by `const&` (large types) or by value (cheap / trivially-copyable types).
- Prefer `constexpr` for compile-time constants and pure functions; use `constinit` for guaranteed static initialization.
- Use `[[nodiscard]]` on functions whose return value must not be ignored (factories, `expected`-returning calls, `empty()`).

## Parameter Passing

| Intent                       | Pass as                 | Notes                                              |
| ---------------------------- | ----------------------- | -------------------------------------------------- |
| Read-only, cheap / trivial   | by value (`int`, etc.)  | ints, enums, pointers, small PODs                  |
| Read-only, expensive to copy | `const T&`              | strings, containers, large structs                 |
| Read-only string             | `std::string_view`      | avoids copies; do not store beyond the call        |
| In-out / mutate caller's obj | `T&`                    | prefer returning a value when feasible             |
| Sink (callee keeps it)       | `T` by value, then move | `void set(std::string s) { name = std::move(s); }` |
| Optional argument            | `std::optional<T>`      | clearer than a sentinel or a pointer               |

- Bundle **> 4 parameters** into a small struct (this also defends against argument-order mistakes).

## Error Handling

- **Pick one strategy per module** and document it:
  - **Exceptions** for truly exceptional, not-recoverable-locally failures. Throw by value, catch by `const&`; provide at least the basic exception-safety guarantee.
  - **`std::expected<T, E>`** (C++23) or a status / error-code type for expected, recoverable outcomes (parsing, I/O, validation).
- Mark functions that cannot throw `noexcept` — especially move operations and destructors (a destructor must not throw).
- Validate inputs at the API boundary. Use `assert` for **internal** invariants (debug-only checks), not for user-facing errors. `[[assume]]` (C++23) is an **optimization hint**, not a check — a false assumption is UB, so use it sparingly and never as a substitute for `assert`.
- Never let an exception escape a destructor or a `noexcept` function — it calls `std::terminate`.

## Class Design

- **Special members**: `= default` / `= delete` explicitly when intent matters; obey Rule of Zero / Five.
- **`explicit`** on single-argument constructors and conversion operators to prevent surprising implicit conversions.
- **Polymorphism**: a base class used polymorphically needs a `virtual` (or `protected` non-virtual) destructor. Mark overrides `override`; mark leaf classes / methods `final` where it helps.
- **Initialize members at declaration** (in-class default member initializers) and use member-init lists in constructors; prefer brace `{}` initialization to avoid narrowing and the most-vexing-parse.
- Prefer **composition over inheritance**; keep the public interface minimal.

## Templates & Concepts

- **Constrain templates with concepts** (C++20) instead of unconstrained `typename` + SFINAE — `template <std::integral T>` or a `requires` clause states the contract and yields readable errors.
- Prefer `if constexpr` over tag dispatch / overload tricks for compile-time branching.
- Keep template definitions in the header (or an `.inl` included at the end of the header); explicit instantiation in a `.cpp` is for deliberately closed type sets.
- **Document each template parameter's requirements** with a `//` line stating the concept / contract (mandatory per Comment Conventions).
- Avoid deep template metaprogramming when a plain function, `constexpr`, or runtime polymorphism is clearer — favor the simplest tool that compiles away.

## Header Hygiene & Includes

- **`#pragma once`** at the top of every header.
- **Include what you use** — include the header for every symbol you name; do not lean on transitive includes.
- **Forward-declare** in headers when only a pointer / reference is needed; include the full definition in the `.cpp`.
- **Never** put `using namespace ...` (especially `std`) at file scope in a header.
- For heavy implementation detail or to cut compile-time coupling, consider the **PIMPL** idiom.

## Concurrency

- Protect shared mutable state with `std::mutex` + `std::scoped_lock` / `std::lock_guard` (RAII locking — never lock / unlock by hand).
- Use `std::atomic<T>` for simple lock-free counters / flags; `std::shared_mutex` for read-heavy data.
- Prefer `std::jthread` (C++20, auto-joining + cooperative `stop_token`) over `std::thread`.
- Document the thread-safety contract of every public class (see Comment Conventions).

## Performance & Data Layout

Optimize for clarity first; reach for these only on a measured-hot path:

- **Measure before optimizing** — profile, do not guess. Keep the readable version unless data says otherwise.
- **Avoid hidden allocations in hot loops** — `reserve()` a vector to its known size; reuse a long-lived scratch buffer across frames / iterations instead of reallocating each pass.
- **Pass non-owning views** (`std::span` / `std::string_view`) to avoid copying containers across call boundaries.
- **Keep hot data POD and contiguous** — prefer flat arrays / struct-of-arrays over node-based containers for cache locality; a tagged struct of fixed fields often beats pointer-chasing a `variant` of heap objects.
- **Pass small trivially-copyable types by value** (they fit in a register); pass large types by `const&`.
- **`constexpr`** to push work to compile time; mark pure helpers `constexpr` where inputs allow.
- Prefer `emplace_back` over `push_back(T(...))`; move into containers rather than copy.

## Tooling & Diagnostics

- **Formatting**: enforce a `.clang-format`; do not hand-format.
- **Linting**: run `clang-tidy` with the project's `.clang-tidy`.
- **Warnings**: build with `-Wall -Wextra -Wpedantic` (and `-Werror` in CI).
- **Sanitizers**: run tests under AddressSanitizer / UBSan (`-fsanitize=address,undefined`), and ThreadSanitizer for concurrent code.

## Default Libraries and Build Tools

**Library Selection Priority**:

1. **C++ Standard Library** (first choice)
2. **Boost** (second choice for general-purpose utilities)
3. **Folly** (second choice for high-performance components)

**Project Management**:

- **Build System**: Default to **CMake** for cross-platform builds
- **Package Manager**: Default to **vcpkg** for dependency management

**Testing Framework**:

- **Match the project's existing framework first.** For a new project, default to a lightweight, fast-to-compile one — **boost-ut** (header-only, macro-free), Catch2, or GoogleTest. Use heavyweight Boost.Test only where a project already standardizes on it. (See the **Testing** section for organization rules.)

## Testing

- **One test file per unit under test**, named after it; mirror the source tree under `tests/`.
- **Name tests by behavior, not by method** — `connect_fails_on_bad_handshake`, not `testConnect`.
- Cover the **contract and the edges** (empty, boundary, error paths), not just the happy path; keep one logical focus per test case.
- No real network / disk / clock in unit tests — inject seams or fakes so tests stay deterministic and fast.
- Tests are first-class code: same naming, layout, comment, and review bar as production code.

## C++-Specific Best Practices

```cpp
// Manages a single logical database connection lifecycle.

// Database access types for the storage layer.
namespace Storage {

// Represents one client connection to the database server.
// Not thread-safe; use one instance per thread or external synchronization.
class DatabaseConnection {
    // Maximum rows fetched per round-trip in batch APIs.
    int maxBatchSize = 1000;

    std::string connectionString;

public:
    // Opens the connection using connectionString.
    void connect();

    void disconnect();
};

}  // namespace Storage

// Good: enum class instead of enum
enum class Status {
    success,
    failure,
    pending
};

// Good: Macro naming
#define MAX_BUFFER_SIZE 1024
#define ENABLE_LOGGING

// Good: Template naming
template<typename T, typename U, int maxSize>
class Cache {
    // T, U are UpperCamelCase (type parameters)
    // maxSize is lowerCamelCase (non-type parameter)
};

// Good: Namespace naming (UpperCamelCase, same as classes)
namespace Http {
namespace Internal {
}  // namespace Internal
}  // namespace Http

// Good: Short names in tight scopes
for (auto& item : collection) {
    item.process();
}

// Good: Follow Core Guidelines for resource management
std::unique_ptr<Resource> createResource() {
    return std::make_unique<Resource>();
}
```
