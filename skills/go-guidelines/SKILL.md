---
name: go-guidelines
description: Go language coding conventions, naming rules, comment style, default libraries, and best practices. This skill overrides external style guides where it defines rules. Load when writing or reviewing Go code.
---

# Go Language Guidelines

## Style Priority (Read First)

When writing or reviewing Go in a project that uses this skill:

1. **This skill wins for code style** — naming, comments, package layout, default libraries, build/test defaults, and any other rule stated in this file take precedence over external guides and over habits from other codebases (Uber Go Style Guide, Google Go Style, Effective Go, team wiki, etc.).
2. **External references fill gaps only** — use the links below when this skill is **silent** on a topic (e.g. reflection, unsafe, cgo, compiler internals). Do not replace or weaken an explicit rule here with a conflicting external convention.
3. **On conflict** — if an external document disagrees with this skill, **follow this skill** for project code.

## Core References

Use these when this skill does not cover the topic:

- [Effective Go](https://go.dev/doc/effective_go) — idiomatic Go conventions
- [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments) — the Go team's review checklist
- [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md) — detailed production-oriented guidance (only where not overridden above)
- [Go Language Specification](https://go.dev/ref/spec) — authoritative language reference

## Go Version Detection

- **Check `go.mod` first** — read the `go` directive (e.g. `go 1.21`) before writing code. Match the module's declared version; do not use features it cannot compile.
- **Prefer modern features** that simplify code, when the version allows:
  - **Go 1.18**: generics, `any` alias for `interface{}`, fuzzing.
  - **Go 1.20**: `errors.Join`, `context.WithCancelCause`, slice-to-array conversions.
  - **Go 1.21**: `min`/`max` built-ins, `clear` built-in, `slices`/`maps`/`cmp` packages, `log/slog` structured logging.
  - **Go 1.22**: `for` loop variable scoping fix, `math/rand/v2`, enhanced routing in `net/http`.
  - **Go 1.23**: `iter` package for range-over-func, `unique` package.
- **Replace legacy idioms** — `any` over `interface{}`, generics over reflection for type-safe containers, `slog` over `log`, `errors.Join` over manual multi-error, `slices.Sort` over `sort.Slice`.

## Naming Conventions

### Naming Table

Go names follow mixedCaps: exported names start with an uppercase letter, unexported with a lowercase letter.

| Element                      | Convention                      | Example                                          |
| ---------------------------- | ------------------------------- | ------------------------------------------------ |
| **Packages**                 | lowercase, short, no underscores | `httpclient`, `userstore`, `ratelimit`          |
| **Exported Types**           | UpperCamelCase                  | `UserManager`, `HTTPClient`                      |
| **Unexported Types**         | lowerCamelCase                  | `connectionPool`, `requestParser`                |
| **Exported Functions/Methods**| UpperCamelCase                  | `ProcessData()`, `ValidateInput()`               |
| **Unexported Functions**     | lowerCamelCase                  | `parseHeader()`, `flushBuffer()`                 |
| **Variables**                | lowerCamelCase                  | `userName`, `maxRetries`                         |
| **Constants (exported)**     | UpperCamelCase                  | `DefaultTimeout`, `MaxBufferSize`                |
| **Constants (unexported)**   | lowerCamelCase                  | `defaultTimeout`, `maxBufferSize`                |
| **Type Parameters**          | UpperCamelCase (single letter)  | `T`, `U`, `K`, `V`                               |
| **Acronyms**                 | All-caps or all-lower (consistent) | `HTTPServer` / `httpServer`, `userID` / `userId` |

**Acronym rule**: treat acronyms as words — `ServeHTTP` (not `ServeHttp`), `userID` (not `userId`) when `ID` is the acronym. Be consistent within a codebase.

### Semantic Naming Rules

Format is not enough — a name must convey **meaning and intent**:

- **Booleans** (variables and predicate functions) read as a yes/no question: prefix with `is` / `has` / `can` / `should` / `use`.
  - `isOpen`, `hasNext`, `canRetry`, `shouldFlush`, `useCache`
  - `func isValid() bool`, `func hasCapacity() bool`
  - Avoid negated names — prefer `isReady` over `isNotReady` (double negatives in conditions are error-prone).
- **Action functions** are verbs or verb-phrases — `connect()`, `parseHeader()`, `flushBuffer()`, `computeHash()`.
- **Getters**: a noun (Go convention: no `Get` prefix) — `name()`, `count()`. **Setters**: `setName()`, `setTimeout()`.
- **Constructors**: `newXxx` for unexported types or `NewXxx` for exported types — `newConnectionPool()`, `NewUserManager()`.
- **Counts / sizes / indices**: `xxxCount` (or `numXxx`) for counts, `xxxSize` for byte/element sizes, `xxxIdx` for indices.
- **Units in the name** whenever a bare number is ambiguous — `timeoutMs`, `sizeBytes`, `delaySeconds`, `widthPx`.
- **Scope governs length** — short names in tight scopes (`i`, `v`, `ctx`, `err`, `buf`), descriptive names for wider scope (`connectionPool`, `maxConcurrentRequests`). Short variable names are idiomatic Go; embrace them in local scope.
- **Abbreviations**: spell words out except well-established ones — `id`, `url`, `http`, `db`, `io`, `ctx`, `err`, `msg`, `buf`, `src`, `dst`.
- **Avoid stutter** — `user.Name()` not `user.UserName()`; package name already provides context.

## File Layout and Organization

### Package and File Structure

- **One cohesive concept per package** — a package name should answer "what does this package provide?", not "what types are in this package?". Avoid `util`, `common`, `misc`, `helpers` packages.
- **One primary type per file**, the file named after the type in lowercase (`user_manager.go` → `UserManager`). Small, tightly-coupled helpers may share the file.
- A package's exported API lives in a `doc.go` or the primary file; internal helpers go in files named by their concern.

### File Order (Top → Bottom)

1. Package clause: `package name`
2. Imports, grouped with a blank line between groups, alphabetized within each group:
   1. Standard library (`"fmt"`, `"net/http"`, …)
   2. Third-party libraries (`"github.com/gin-gonic/gin"`, …)
   3. This module's packages (`"example.com/project/internal/..."`)
3. Package-level `var` / `const` blocks
4. Package-level type definitions (exported first, then unexported)
5. Constructor functions (`NewXxx` / `newXxx`)
6. Methods grouped by type, exported methods first, related methods together
7. Unexported helper functions at the bottom

Use `goimports` (or `gofumpt`) to maintain import grouping automatically.

### Type Member Order

For a struct type, group declarations in the same file in this order:
1. Type definition (struct with fields)
2. Constructor: `NewXxx()` or `newXxx()`
3. Exported methods (alphabetical or logical grouping)
4. Unexported methods (alphabetical or logical grouping)

## Comment Conventions

### What Must Be Documented

**Mandatory** — these MUST carry a `//` doc comment immediately above the declaration:

- **All exported identifiers** — types, functions, methods, constants, variables (this is enforced by `go vet` and many linters). The comment must start with the name of the item.
- **Packages** — a package comment in a `doc.go` file (or the primary file) describing the package's purpose and key abstractions.
- **Exported interfaces** — describe the contract: what implementations must satisfy.
- **Complex unexported logic** — non-obvious algorithms, invariants, or concurrency contracts.

**Optional / discouraged**:

- Trivial private helpers, obvious getters/setters, and self-documenting code need no comment.
- Never write a comment that merely restates the code (`// increment i`).
- Comment the **why**, not the **what** — and prefer renaming over explaining a poor name.
- Use `// TODO(author):` / `// FIXME(author):` with an owner for deferred work.

### General Rules

- **Use `//` only** for all comments. Do **not** use `/* */` block comments anywhere in project Go code.
- Write documentation as **plain `//` sentences** — do **not** use metadata prefixes like `brief:`, `details:`, or `see:` on comment lines.
- The first sentence of a doc comment should be a one-line summary that begins with the name being declared.
- Write multi-line documentation as **consecutive `//` lines** (one thought per line when it helps readability).
- Prefer **English** for all comments.
- **No decorative section banners** — do not use lines like `// ---------- Section ----------` or `// ==== Foo ====`. Use a normal `//` sentence if a boundary needs explaining, or let the code structure speak for itself.

### Package Doc

```go
// Package httputil provides HTTP client helpers, transport wrappers,
// and middleware utilities for outgoing requests.
package httputil
```

For larger packages, put the package comment in a `doc.go` file.

### Type Documentation

```go
// ConnectionPool owns a bounded set of reusable TCP connections
// to a single upstream host. Connections are acquired via Acquire
// and must be returned with Release.
// Acquire may block when the pool is exhausted.
type ConnectionPool struct {
    // ...
}
```

### Function Documentation

```go
// Get sends an HTTP GET request to url and returns the response body
// on success.
// The caller must close resp.Body.
// If ctx is canceled, the underlying request is aborted.
func (c *Client) Get(ctx context.Context, url string) (*http.Response, error) {
```

- **Constructors**: state what the constructed value holds and any initialization side effects.
- **Template functions**: document type parameter constraints in a plain `//` line.

### Variable and Member Documentation

- Exported constants and variables: one `//` line above the declaration.
```go
// DefaultMaxRetries is the default number of retry attempts for idempotent requests.
const DefaultMaxRetries = 3
```
- **Local variables**: comment only when the name cannot carry the intent. Prefer renaming over commenting.

### Inline and Implementation Comments

- Use `//` inside function bodies for non-obvious steps, invariants, or TODO/FIXME:
```go
// TODO(author): add cancellation token support
// FIXME: handle partial writes on Windows
```
- Do not use `/* */` for commented-out code; delete dead code.

## Decomposition Granularity

- **Package**: one cohesive responsibility / bounded context. A package should do one thing and do it well. Map a package to a directory. Avoid circular imports by design.
- **File**: under **800 lines** (global rule). Split when a file accumulates unrelated concerns — not merely when it grows.
- **Type**: a single responsibility. Keep the exported interface minimal (Minimal Export Principle) — roughly **≤ 10–15 exported methods**. Prefer **composition over deep struct embedding**. Accept interfaces, return structs.
- **Function**: under **50 lines** (global rule), at a **single level of abstraction**, with **≤ 4 parameters** — bundle more into a small struct (parameter object pattern).
- **Method over function** when it operates on a type's data; **function over method** when it needs no receiver — this shrinks the API surface and improves testability.

## Package & Interface Design

- **Accept interfaces, return structs** — callers define the interface they need (consumer-side interface), not the producer.
- **Small interfaces** — 1–4 methods is the norm. Prefer single-method interfaces (`io.Reader`, `io.Writer`) for maximum composability.
- **Minimal export** — only export what callers genuinely need. Default to unexported and export only when a real consumer exists.
- **Avoid package-level state** — pass dependencies explicitly via constructor injection. Package-level globals make testing and concurrency management harder.
- **Use `internal/`** directory for packages that must not be imported by external modules.
- **`context.Context` as the first parameter** for functions that cross API boundaries, do I/O, or may be canceled. Never store a context in a struct.

## Error Handling

- **Handle errors explicitly** — never ignore an error return. If a caller can't meaningfully handle it, wrap and propagate.
- **Error wrapping**: use `fmt.Errorf("...: %w", err)` to wrap with context; callers can inspect with `errors.Is` / `errors.As`.
- **Sentinel errors**: exported `var ErrXxx = errors.New("...")` for specific, comparable error conditions.
- **Custom error types**: implement the `error` interface; prefer unexported types with exported constructors.
- **`errors.Join`** (Go 1.20+) for aggregating multiple errors.
- **Panic is for bugs only** — use `panic` for invariant violations that indicate a programmer error, not for expected runtime failures. Never recover from a panic without re-wrapping or logging.
- **Validate at boundaries** — check inputs at the public API surface; fail fast with clear messages.

## Concurrency

- **Share memory by communicating** — prefer channels over mutexes for coordinating goroutines. Use mutexes only for protecting shared mutable state.
- **`sync.Mutex` + `defer mu.Unlock()`** for simple critical sections. Use `sync.RWMutex` for read-heavy data.
- **Channels**: prefer sized channels (`make(chan T, n)`) when the capacity is known. Unbuffered channels for synchronization handoffs.
- **Goroutine lifecycle**: every goroutine must have a clear exit path. Use `context.Context` or done channels to signal termination. Never leak goroutines.
- **`sync.WaitGroup`** for waiting on a known set of goroutines. `errgroup.Group` for concurrent work with error propagation.
- **`sync.Once`** for one-time initialization; `sync.Pool` for reusable temporary objects on hot paths.
- **Document the concurrency contract** of every exported type: whether it is safe for concurrent use, and under what conditions.

## Performance & Memory

Optimize for clarity first; reach for these only on a measured-hot path:

- **Measure before optimizing** — use `go test -bench` and `pprof`; do not guess.
- **Minimize allocations** in hot loops — pre-allocate slices with `make([]T, 0, n)` when the size is known; reuse buffers via `sync.Pool` across iterations.
- **Pass by value** for small structs; pass by pointer for large structs or when mutation is needed. The cut-off is typically 2–3 machine words.
- **`strings.Builder`** over `+=` for building strings; `bytes.Buffer` for binary data.
- **Avoid boxing** — `interface{}`/`any` causes heap allocation. Use generics instead for type-safe, zero-allocation containers.
- **`const`** and package-level `var` for compile-time / initialization-time constants; avoid repeated computation of the same value.
- **Use `io.Copy`** for streaming data instead of reading entire contents into memory.
- **Slice tricks**: `s = s[:len(s):len(s)]` to cap after append; avoid holding references to large backing arrays.

## Tooling & Diagnostics

- **Formatting**: always run `gofmt` or `gofumpt` before committing. Never hand-format Go code.
- **Linting**: run `golangci-lint` with the project's `.golangci.yml`. Enable at minimum: `errcheck`, `gosimple`, `govet`, `ineffassign`, `staticcheck`, `unused`.
- **Race detector**: run tests with `go test -race`. Required for any code that uses goroutines or channels.
- **Vet**: run `go vet ./...` as part of CI; it catches suspicious constructs.
- **Staticcheck** (`honnef.co/go/tools/cmd/staticcheck`) for deeper static analysis beyond `go vet`.

## Default Libraries and Frameworks

**Library Selection Priority**:
1. **Go Standard Library** (first choice)
2. **Well-established third-party libraries** (second choice)

**Recommended Defaults**:

| Category            | First Choice                | Notes                              |
| ------------------- | --------------------------- | ---------------------------------- |
| **JSON**            | `encoding/json` (stdlib)    | Use `encoding/json/v2` if available |
| **HTTP Server**     | `net/http` (stdlib)         | Enhanced routing in Go 1.22+       |
| **HTTP Client**     | `net/http` (stdlib)         | Always pass `ctx`                  |
| **Web Framework**   | `gin-gonic/gin`             | High-performance, widely adopted   |
| **WebSocket**       | `gobwas/ws`                 | Zero-copy, low-allocation          |
| **Testing**         | `testing` (stdlib)          | Use `stretchr/testify` for assertions |
| **Mocking**         | `stretchr/testify/mock`     | Or `uber-go/mock` for code-gen     |
| **Structured Logging** | `log/slog` (stdlib, 1.21+) | Replace `log` and third-party loggers |
| **Configuration**   | `envconfig` or `viper`      | Simple vs. rich config              |
| **Redis**           | `redis/go-redis`            | Widely adopted, full-featured       |
| **SQL**             | `database/sql` + driver     | Use `sqlc` for type-safe code-gen  |
| **ORM**             | Avoid; use `sqlc` + raw SQL | ORMs obscure query behavior         |
| **Validation**      | `go-playground/validator`   | Struct-tag based                    |
| **CLI**             | `cobra` + `viper`           | For complex CLIs                    |

## Testing

- **One test file per source file**, named `xxx_test.go`; mirror the source tree.
- **Name tests by behavior, not by method** — `TestConnect_FailsOnBadHandshake`, not `TestClient_Connect`.
- **Table-driven tests** are the Go standard for multiple input/output pairs. Use `t.Run()` for sub-tests.
- Cover the **contract and the edges** (empty, boundary, error paths), not just the happy path; keep one logical focus per test case.
- Use **interfaces and injection** to avoid real network/disk/clock in unit tests; fakes and mocks keep tests deterministic and fast.
- **Test helpers** must call `t.Helper()` so failures report the caller's location.
- Tests are first-class code: same naming, layout, comment, and review bar as production code.
- Run tests with `-race` and `-count=1` (disable caching) in CI.

## Go-Specific Best Practices

```go
// Package user manages user accounts and authentication sessions.
package user

import (
    "context"
    "errors"
    "fmt"
    "sync"
    "time"
)

// DefaultTimeout is the default context timeout for user operations.
const DefaultTimeout = 30 * time.Second

// ErrNotFound is returned when a user cannot be found.
var ErrNotFound = errors.New("user not found")

// Manager handles user lifecycle with thread-safe access.
// Acquired managers should be closed when no longer needed.
type Manager struct {
    mu    sync.RWMutex
    store UserStore
}

// UserStore defines the persistence operations required by Manager.
type UserStore interface {
    Find(ctx context.Context, id string) (*User, error)
    Save(ctx context.Context, u *User) error
}

// NewManager creates a Manager backed by the provided store.
func NewManager(store UserStore) *Manager {
    return &Manager{store: store}
}

// Find retrieves a user by id. Returns ErrNotFound if the user
// does not exist in the store.
func (m *Manager) Find(ctx context.Context, id string) (*User, error) {
    ctx, cancel := context.WithTimeout(ctx, DefaultTimeout)
    defer cancel()

    u, err := m.store.Find(ctx, id)
    if err != nil {
        return nil, fmt.Errorf("find user %s: %w", id, err)
    }
    return u, nil
}

// User represents a registered user in the system.
type User struct {
    ID        string
    Name      string
    Email     string
    CreatedAt time.Time
}

// IsActive reports whether the user account is in good standing.
func (u *User) IsActive() bool {
    return u.Email != ""
}

// Good: Short names in tight scopes (idiomatic Go).
for i, v := range items {
    if v.IsActive() {
        processActive(v)
    }
}

// Good: Generics eliminate interface{} and reflection.
func Map[T, U any](slice []T, fn func(T) U) []U {
    result := make([]U, len(slice))
    for i, v := range slice {
        result[i] = fn(v)
    }
    return result
}

// Good: Context as first parameter; explicit error handling.
func (c *Client) fetch(ctx context.Context, url string) ([]byte, error) {
    req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
    if err != nil {
        return nil, fmt.Errorf("create request: %w", err)
    }
    resp, err := c.http.Do(req)
    if err != nil {
        return nil, fmt.Errorf("execute request: %w", err)
    }
    defer resp.Body.Close()
    return io.ReadAll(resp.Body)
}

// Good: Accept interfaces, return structs.
type Logger interface {
    Info(msg string, args ...any)
}

// Good: Function option pattern for optional configuration.
type Option func(*Manager)

func WithTimeout(d time.Duration) Option {
    return func(m *Manager) { m.timeout = d }
}
```
