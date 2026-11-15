---
name: python-guidelines
description: Python language coding conventions, naming rules, comment style, default libraries, and best practices. This skill overrides external style guides where it defines rules. Load when writing or reviewing Python code.
---

# Python Language Guidelines

## Style Priority (Read First)

When writing or reviewing Python in a project that uses this skill:

1. **This skill wins for code style** — naming, comments, module layout, default libraries, build/test defaults, and any other rule stated in this file take precedence over external guides and over habits from other codebases (PEP 8, Google Python Style, Black defaults, team wiki, etc.).
2. **External references fill gaps only** — use the links below when this skill is **silent** on a topic (e.g. metaclasses, C extensions, packaging internals). Do not replace or weaken an explicit rule here with a conflicting external convention.
3. **On conflict** — if an external document disagrees with this skill, **follow this skill** for project code.

## Core References

Use these when this skill does not cover the topic:

- [PEP 8 – Style Guide for Python Code](https://peps.python.org/pep-0008/) — canonical Python style
- [PEP 257 – Docstring Conventions](https://peps.python.org/pep-0257/) — docstring format
- [PEP 484 – Type Hints](https://peps.python.org/pep-0484/) — type hint specification
- [Python Language Reference](https://docs.python.org/3/reference/) — authoritative language spec
- [Python Standard Library](https://docs.python.org/3/library/) — stdlib module reference

## Python Version Detection

- **Check `pyproject.toml` first** — read `requires-python` or the `[tool.uv]` / `[tool.poetry]` section. For `setup.py` / `setup.cfg`, check `python_requires`. Match the project's minimum version; do not use features it cannot run.
- **Prefer modern features** that simplify code, when the version allows:
  - **Python 3.8**: walrus operator `:=`, `functools.cached_property`, positional-only parameters (`/`), `TypedDict`.
  - **Python 3.9**: built-in generic types (`list[int]`, `dict[str, int]`), `str.removeprefix` / `.removesuffix`, dict union `|`.
  - **Python 3.10**: `match`/`case` pattern matching, `|` union types (`int | None`), `dataclass(slots=True)`, `strict` parameter for `zip`.
  - **Python 3.11**: `Self` type, `ExceptionGroup`, `tomllib` in stdlib, fine-grained error locations, `asyncio.TaskGroup`.
  - **Python 3.12**: `type` statement (`type Point = tuple[float, float]`), `@override` decorator, `itertools.batched`, f-string improvements.
  - **Python 3.13**: free-threaded mode (experimental), new `copy.replace()`.
- **Replace legacy idioms** — `pathlib` over `os.path`, f-strings over `.format()` / `%`, `dataclasses` over manual `__init__`, `match` over deep `if`/`elif` chains, `list[int]` over `List[int]`, `int | None` over `Optional[int]`.

## Code Layout

- **Indentation**: Use 4 spaces per indentation level (never tabs).
- **Maximum Line Length**: Limit all lines to **79 characters**; docstrings/comments to **72 characters**. For projects that already adopt 88 or 120, match the existing convention.
- **Blank Lines**:
  - Two blank lines around top-level function and class definitions.
  - One blank line around method definitions inside a class.
  - Use blank lines sparingly within function bodies to separate logical sections.
- **Source File Encoding**: Always use UTF-8. Declare `# -*- coding: utf-8 -*-` only if the project standardizes it.
- **Trailing Whitespace**: None. Configure your editor to strip it.
- **File ending**: A single newline at end of file.

### Imports

- One import per line (except `from X import a, b, c`).
- Group imports with a blank line between groups, alphabetized within each group:
  1. Standard library (`import os`, `from pathlib import Path`)
  2. Third-party libraries (`import httpx`, `from fastapi import FastAPI`)
  3. Local application imports (`from .models import User`, `from ..utils import logging`)
- Prefer absolute imports over relative imports for clarity.
- Never use `from module import *` — it pollutes the namespace.
- Use `isort` or `ruff` to maintain import ordering automatically.

## Naming Conventions

### Naming Table

| Element                      | Convention                      | Example                                          |
| ---------------------------- | ------------------------------- | ------------------------------------------------ |
| **Packages/Modules**         | lowercase, short, no underscores | `mypackage`, `utils`, `http_client` (file)      |
| **Classes**                  | CapWords (PascalCase)           | `UserManager`, `HTTPClient`                      |
| **Exceptions**               | CapWords + "Error" suffix       | `ValueError`, `ConnectionError`                  |
| **Functions/Methods**        | lowercase_with_underscores      | `process_data()`, `validate_input()`             |
| **Variables**                | lowercase_with_underscores      | `user_name`, `connection_pool`                   |
| **Constants**                | UPPER_CASE_WITH_UNDERSCORES     | `MAX_RETRIES`, `DEFAULT_TIMEOUT`                 |
| **Type Variables**           | CapWords (short, 1–3 letters)   | `T`, `AnyStr`, `KT`, `VT`                        |
| **Private Attributes**       | Single leading underscore       | `_internal_value`, `_helper_method()`            |
| **Name Mangling**            | Double leading underscore       | `__private_attr` (becomes `_ClassName__private_attr`) |
| **Dunder Methods**           | Double leading + trailing       | `__init__`, `__str__`, `__repr__`                |

### Semantic Naming Rules

Format is not enough — a name must convey **meaning and intent**:

- **Booleans** (variables and predicate functions) read as a yes/no question: prefix with `is_` / `has_` / `can_` / `should_` / `use_`.
  - `is_open`, `has_next`, `can_retry`, `should_flush`, `use_cache`
  - `def is_valid(self) -> bool:`, `def has_capacity(self) -> bool:`
  - Avoid negated names — prefer `is_ready` over `is_not_ready` (double negatives in conditions are error-prone).
- **Action functions** are verbs or verb-phrases — `connect()`, `parse_header()`, `flush_buffer()`, `compute_hash()`.
- **Getters / setters**: use `@property` for computed attributes (noun); use `set_xxx()` for explicit setters when a property setter is insufficient.
- **Factory functions**: `make_xxx()` / `create_xxx()` — `make_connection_pool()`, `create_user()`.
- **Counts / sizes / indices**: `xxx_count` (or `num_xxx`) for counts, `xxx_size` for byte/element sizes, `xxx_idx` for indices.
- **Units in the name** whenever a bare number is ambiguous — `timeout_ms`, `size_bytes`, `delay_seconds`, `width_px`.
- **Scope governs length** — short names in tight scopes (`i`, `j`, `k`, `x`, `ctx`, `buf`, `fp`), descriptive names for wider scope (`connection_pool`, `max_concurrent_requests`).
- **Abbreviations**: spell words out except well-established ones — `id`, `url`, `http`, `db`, `io`, `ctx`, `msg`, `buf`, `src`, `dst`.
- **Avoid shadowing built-ins** — do not name variables `list`, `dict`, `id`, `type`, `str`, `input`, `filter`. Use `lst`, `dct`, `id_`, `typ`, `input_` if necessary.
- **Iterable unpacking**: use descriptive names in comprehensions — `[user.name for user in active_users]`, not `[x.name for x in xs]`.

## File Layout and Organization

### Module Structure

- **One cohesive concept per module** — a module name should answer "what does this module provide?". Avoid `util.py`, `common.py`, `helpers.py` as dumping grounds.
- **One primary class per file**, named after the class (lowercase: `user_manager.py` → `UserManager`). Small, tightly-coupled helpers may share the file.
- Group related modules into packages with `__init__.py`. Re-export only the public API in `__init__.py`.

### File Order (Top → Bottom)

1. Shebang line (if executable): `#!/usr/bin/env python3`
2. Encoding declaration (only if project standardizes): `# -*- coding: utf-8 -*-`
3. Module docstring: `"""One-line summary of the module's purpose."""`
4. `from __future__ import annotations` (if needed for forward references)
5. `__all__` declaration (if the module defines a public API)
6. Imports (grouped as described above)
7. Module-level constants
8. Module-level type aliases
9. Class definitions (exported first)
10. Function definitions (exported first)
11. `if __name__ == "__main__":` block at the very bottom

### Class Member Order

Order by **visibility first** (what a reader needs is at the top), then by kind:

1. Class docstring
2. `__slots__` (if used)
3. Class-level constants and type aliases
4. `__init__` (constructor)
5. Properties (`@property`)
6. Dunder methods (`__repr__`, `__str__`, `__eq__`, `__hash__`, etc.)
7. Public methods (group related methods together)
8. Private methods (single underscore prefix)

## Comment Conventions

### What Must Be Documented

**Mandatory** — these MUST carry a docstring or `#` comment:

- **All public modules** — a docstring at the top describing the module's purpose.
- **All public classes** — purpose, key invariants, and thread-safety expectations.
- **All public functions/methods** — behavior, parameters, return value, and exceptions raised.
- **Exported constants and type aliases** — a `#` comment above describing their meaning.
- **Complex private helpers** — non-obvious algorithms, invariants, or side effects.

**Optional / discouraged**:

- Trivial private helpers, obvious getters/setters, and self-documenting code need no comment.
- Never write a comment that merely restates the code (`# increment i`).
- Comment the **why**, not the **what** — and prefer renaming over explaining a poor name.
- Use `# TODO(name):` / `# FIXME(name):` with an owner for deferred work.

### General Rules

- **Use `#` for inline comments**; use `"""` docstrings for module/class/function documentation.
- Write documentation as **plain sentences** — do **not** use metadata prefixes like `brief:`, `details:`, or `see:` on comment lines.
- **Inline comments**: put at end of line only for short clarifications, separated by at least two spaces from the code.
- Prefer **English** for all docstrings and comments.
- **No decorative section banners** — do not use lines like `# ---------- Section ----------` or `# ==== Foo ====`. Use a normal `#` sentence if a boundary needs explaining, or let the code structure speak for itself.

### Module Docstring

Place at the very top of the file, before imports:

```python
"""HTTP client helpers for synchronous and async requests.

Provides ConnectionPool, RetryStrategy, and middleware hooks
for outgoing HTTP calls.
"""
```

### Class Docstring

Place immediately after the class definition line:

```python
class ConnectionPool:
    """Owns a bounded set of reusable TCP connections to upstream hosts.

    Connections are acquired via acquire() and must be returned
    with release(). Destruction waits for all lent connections
    to be returned or times out per pool policy.

    Not thread-safe; use one instance per event loop or protect
    with external synchronization.
    """
```

### Function Docstring

Use the "Args / Returns / Raises" style for non-trivial functions:

```python
def get(self, url: str, timeout_ms: int) -> bytes:
    """Send an HTTP GET request and return the response body.

    Args:
        url: Absolute or root-relative URL; must be non-empty.
        timeout_ms: Maximum wait per attempt in milliseconds;
            must be positive.

    Returns:
        Response body bytes; empty if the server returns no body.

    Raises:
        ConnectionError: If the connection cannot be established.
        TimeoutError: If the request times out.
    """
```

For simple functions, a one-line docstring is sufficient:

```python
def is_active(self) -> bool:
    """Return True if the user account is in good standing."""
    return self.email != ""
```

### Variable and Constant Documentation

- **Class attributes** and **module-level constants**: a `#` comment above the declaration.

```python
class DatabaseConnection:
    # Upper bound on simultaneous open connections.
    max_pool_size: int = 8

    # DSN or connection URI passed to the driver.
    connection_string: str

# Default number of retry attempts for idempotent requests.
DEFAULT_MAX_RETRIES: int = 3
```

- **Local variables**: comment only when the name cannot carry the intent. Prefer renaming over commenting.

### Inline and Implementation Comments

- Use `#` inside function bodies for non-obvious steps, invariants, or TODO/FIXME:

```python
# TODO(username): add cancellation token support
# FIXME: handle partial writes on Windows
```

- Do not use `""" """` for commented-out code; delete dead code.

## Type Hints

- **Always use type hints** for public APIs (functions, methods, classes).
- Follow [PEP 484](https://peps.python.org/pep-0484/) for type hint syntax.
- Use `from __future__ import annotations` for forward references and lazy evaluation (Python 3.7+ until 3.13, then it's the default).
- Prefer built-in generic types (`list[int]`, `dict[str, int]`, `tuple[int, ...]`) over `typing` module equivalents (Python 3.9+).
- Prefer `X | None` over `Optional[X]` (Python 3.10+).
- Use `collections.abc` for abstract collection types: `Iterable[T]`, `Sequence[T]`, `Mapping[K, V]`.
- Use `TypeAlias` for type aliases; plain assignment for simple aliases (Python 3.12+ `type` statement).
- Use `TypedDict` or `dataclass` / `Pydantic` models for structured data instead of bare `dict`.
- Use `Self` type hint (Python 3.11+) for methods returning the instance type.

```python
from __future__ import annotations

from collections.abc import Iterable, Sequence
from typing import Self, TypeAlias

# Type alias
JSON: TypeAlias = dict[str, "JSON"] | list["JSON"] | str | int | float | bool | None

def process_users(users: Sequence[User], limit: int = 100) -> dict[str, int]:
    """Process users and return statistics keyed by user ID."""
    ...

def find_user(user_id: int) -> User | None:
    """Find user by ID; returns None if not found."""
    ...

class Builder:
    def set_name(self, name: str) -> Self:
        self._name = name
        return self
```

## Decomposition Granularity

- **Module**: one cohesive responsibility / bounded context. Avoid modules named `util`, `common`, or `helpers`.
- **File**: under **800 lines** (global rule). Split when a module accumulates unrelated concerns — not merely when it grows.
- **Class**: a single responsibility. If groups of methods touch **disjoint** subsets of the attributes, split the class. Keep the public interface minimal (Minimal Export Principle) — roughly **≤ 10–15 public methods**. Prefer **composition over deep inheritance**.
- **Function**: under **50 lines** (global rule), at a **single level of abstraction**, with **≤ 4 parameters** — bundle more into a small dataclass or TypedDict.
- **Free function over method** when it needs no access to private state — this shrinks the class interface and improves testability.
- Prefer **dataclasses** for pure data containers; prefer **Pydantic** models when validation or serialization is needed.

## Resource Management

- **Context managers (`with` statement) always** — for files, sockets, locks, database connections, and any resource needing deterministic cleanup.
- Implement `__enter__` / `__exit__` for custom resource types, or use `contextlib.contextmanager` for generator-based context managers.
- Use `contextlib.closing()` for legacy objects with `.close()` but no context manager support.
- Use `contextlib.ExitStack` to manage multiple context managers dynamically at runtime.
- Never rely on `__del__` for cleanup — it is non-deterministic and may never run.

```python
# Good: Context manager for files
with open("data.txt", encoding="utf-8") as f:
    content = f.read()

# Good: ExitStack for dynamic resources
from contextlib import ExitStack

with ExitStack() as stack:
    files = [stack.enter_context(open(f"part_{i}.txt")) for i in range(5)]
    process_files(files)

# Good: Custom context manager via generator
from contextlib import contextmanager

@contextmanager
def temporary_file(path: Path):
    path.touch()
    try:
        yield path
    finally:
        path.unlink(missing_ok=True)
```

## Error Handling

- **Be specific** — catch specific exception types (`ValueError`, `OSError`), never bare `except:` or `except Exception:` unless at the outermost boundary.
- **Exception chaining**: use `raise ... from err` to preserve the original traceback when wrapping.
- **Custom exceptions**: inherit from `Exception` (not `BaseException`). Export them from the module where they make semantic sense. Include meaningful attributes (not just a message string).
- **LBYL vs EAFP**: prefer EAFP (ask forgiveness, not permission) — use `try`/`except` rather than pre-checks. Exception: validation at API boundaries where `if` is clearer.
- **`finally` for cleanup** — use `finally` to release resources when a context manager is unavailable.
- **Never suppress exceptions silently** — at minimum, log the error. An empty `except: pass` is a bug unless thoroughly justified.
- **`assert` is for debugging, not for error handling** — assertions are stripped with `-O`; never use them to validate user input or runtime conditions.

```python
# Good: Specific catch, chaining
try:
    user = service.get_user(user_id)
except ServiceError as e:
    raise UserNotFoundError(f"User {user_id} not found") from e

# Good: EAFP pattern
try:
    value = cache[key]
except KeyError:
    value = compute_value(key)
    cache[key] = value
```

## Async & Concurrency

- **`asyncio` for I/O-bound concurrency** — prefer `asyncio` over threading for network and file I/O. Use `async def` / `await` throughout.
- **`asyncio.TaskGroup`** (Python 3.11+) for structured concurrency over `asyncio.gather()`.
- **Never block the event loop** — do not call `time.sleep()` in async code (use `await asyncio.sleep()`); do not call synchronous I/O (use async equivalents or `run_in_executor`).
- **Threading** for CPU-bound or truly blocking tasks that lack async equivalents — use `concurrent.futures.ThreadPoolExecutor`.
- **Multiprocessing** for CPU-bound parallel work — use `concurrent.futures.ProcessPoolExecutor` or `multiprocessing`.
- **`asyncio.Lock` / `asyncio.Semaphore`** for coordinating async tasks; `threading.Lock` for thread synchronization.
- **Document thread-safety** in class docstrings — is this type designed for use from multiple threads/event loops?
- **Shared mutable state**: minimize it. Prefer message passing (`asyncio.Queue`, `queue.Queue`) over shared state with locks.

```python
# Good: Structured concurrency with TaskGroup (Python 3.11+)
async def fetch_all(urls: list[str]) -> list[Response]:
    async with asyncio.TaskGroup() as tg:
        tasks = [tg.create_task(fetch(url)) for url in urls]
    return [t.result() for t in tasks]

# Good: Run blocking code in executor
result = await asyncio.get_event_loop().run_in_executor(
    None, blocking_cpu_work, data
)
```

## Performance & Memory

Optimize for clarity first; reach for these only on a measured-hot path:

- **Measure before optimizing** — use `cProfile`, `py-spy`, or `timeit`; do not guess.
- **Minimize allocations in hot loops** — reuse objects, prefer `list` over `tuple` when growing, use `array.array` for homogeneous numeric data.
- **Generators over lists** — use `yield` or generator expressions for large sequences to avoid materializing entire collections in memory.
- **`__slots__`** for classes with millions of instances — reduces per-instance memory overhead.
- **`functools.lru_cache` / `functools.cache`** for expensive pure-function results.
- **`dataclass(slots=True)`** (Python 3.10+) for compact data containers.
- **Local variable binding** in loops (`items = dict_.items; for k, v in items():`) avoids repeated attribute lookups on hot paths.
- **`map()` / `filter()` / `itertools`** can be faster than equivalent comprehensions for simple operations on large data — measure to decide.
- **`orjson`** for high-throughput JSON; **`polars`** over `pandas` for large-scale data processing.

## Tooling & Diagnostics

- **Formatting**: use `ruff format` or `black`. Never hand-format Python code. Configure in `pyproject.toml`.
- **Linting**: use `ruff` for comprehensive, fast linting. Enable at minimum: `E` (pycodestyle errors), `F` (pyflakes), `I` (isort), `N` (pep8-naming), `UP` (pyupgrade), `B` (flake8-bugbear).
- **Type checking**: run `mypy` or `pyright` with strict settings in CI. Enable `check_untyped_defs = true` in mypy.
- **Import sorting**: `ruff check --select I --fix` or `isort`.
- **Security**: run `bandit` for common security issues; `pip-audit` for dependency vulnerabilities.

## Default Libraries and Tools

**Library Selection Priority**:
1. **Python Standard Library** (first choice)
2. **Well-established third-party libraries** (second choice)

### General-Purpose Defaults

| Category              | First Choice                  | Notes                                   |
| --------------------- | ----------------------------- | --------------------------------------- |
| **HTTP Client**       | `httpx` (async + sync)        | Modern; `requests` for sync-only codebases |
| **HTTP Server**       | `FastAPI`                     | High-performance, typed, auto-docs      |
| **Full-Stack**        | `Django`                      | When you need admin, ORM, auth out of box |
| **JSON**              | `json` (stdlib)               | `orjson` for high-throughput            |
| **Testing**           | `pytest`                      | Fixtures, parametrize, rich plugin ecosystem |
| **Mocking**           | `unittest.mock` (stdlib)      | `pytest-mock` for cleaner syntax        |
| **Linting/Formatting**| `ruff`                        | Replaces flake8, isort, pyupgrade, black |
| **Type Checking**     | `mypy` or `pyright`           | Both are excellent; match the project   |
| **CLI**               | `typer`                       | Modern; `click` if simpler CLI needed   |
| **Async**             | `asyncio` (stdlib)            | `anyio` for trio compatibility          |
| **Validation/Models** | `pydantic` v2                 | Parse-don't-validate; built-in JSON Schema |
| **Data Processing**   | `polars`                      | Faster, lower memory than pandas for large data |
| **ORM**               | `sqlalchemy` 2.0+             | Explicit, not magic; use with `alembic` |
| **Migrations**        | `alembic`                     | SQLAlchemy-native migration tool        |
| **Configuration**     | `pydantic-settings`           | Type-safe env/config loading            |
| **Logging**           | `logging` (stdlib)            | `loguru` for simpler API                |
| **Serialization**     | `pydantic`                    | JSON Schema out of the box              |
| **File Paths**        | `pathlib` (stdlib)            | Never use `os.path` for new code        |

### Project Management

- **Package Manager**: `uv` (preferred) or `poetry`. `uv` is dramatically faster and handles Python version management.
- **Virtual Environment**: `uv venv` (or standard library `venv`).
- **Build**: `hatchling` or `setuptools` as the build backend (declared in `pyproject.toml`).

## Testing

- **One test file per source module**, named `test_xxx.py`; mirror the source tree under `tests/`.
- **Name tests by behavior, not by method** — `test_connect_fails_on_bad_handshake`, not `test_connect`.
- **Parametrize** inputs with `@pytest.mark.parametrize` instead of loops — better failure reporting.
- Cover the **contract and the edges** (empty, boundary, error paths), not just the happy path; keep one logical focus per test case.
- Use **fixtures** for shared setup; `conftest.py` for fixtures shared across test modules.
- **No real network/disk/clock** in unit tests — inject dependencies, use `pytest-mock`, or provide fakes. Use `monkeypatch` for global state.
- **`tmp_path` / `tmp_path_factory`** for file-system tests (pytest built-in fixtures).
- **Async tests**: install `pytest-asyncio`; mark with `@pytest.mark.asyncio` or use `asyncio_mode = "auto"`.
- Tests are first-class code: same naming, layout, comment, and review bar as production code.

## LLM Application Development

When building LLM-related applications (chatbots, agents, RAG pipelines, tool-calling workflows, etc.), use the **LangChain / LangGraph** ecosystem as the default technology stack.

### Core Stack

- **LLM Orchestration**: `langchain` — chains, prompts, output parsers, retrievers
- **Agent Workflows**: `langgraph` — stateful, graph-based multi-step agent orchestration
- **Autonomous Agents**: `deepagents` — high-level autonomous agent framework built on LangGraph
- **Integrations**: LangChain integrations for model providers, vector stores, tools, etc.

### Reference Documentation

Fetch these when you need API details, usage patterns, or examples:

| Resource | URL |
| --- | --- |
| LangChain API Reference | https://reference.langchain.com/python/langchain |
| LangGraph API Reference | https://reference.langchain.com/python/langgraph |
| DeepAgents API Reference | https://reference.langchain.com/python/deepagents |
| Integrations Overview | https://reference.langchain.com/python/integrations/overview |
| LangChain Guide | https://docs.langchain.com/oss/python/langchain/overview |
| LangGraph Guide | https://docs.langchain.com/oss/python/langgraph/overview |
| DeepAgents Guide | https://docs.langchain.com/oss/python/deepagents/overview |

### Best Practices

- Prefer `langgraph` over raw `langchain` chains for multi-step or stateful workflows.
- Use typed `TypedDict` or `Pydantic` models for graph state schemas.
- Define tools with `@tool` decorator and clear docstrings (the LLM reads them).
- Use structured output (`with_structured_output()`) over free-text parsing when possible.
- Handle LLM errors (rate limits, timeouts) with retry/fallback patterns.
- Stream responses via `.stream()` / `.astream()` for better UX in interactive apps.

## Python-Specific Best Practices

```python
"""User management module for account lifecycle operations.

Provides Manager for CRUD operations and User model for data transfer.
Not thread-safe; synchronize externally if shared across threads.
"""

from __future__ import annotations

import asyncio
import logging
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Self, TypeAlias

# Default timeout for user operations in milliseconds.
DEFAULT_TIMEOUT_MS: int = 30_000

# Type alias for JSON-compatible data.
JSON: TypeAlias = dict[str, "JSON"] | list["JSON"] | str | int | float | bool | None

logger = logging.getLogger(__name__)


@dataclass(slots=True)
class User:
    """Represents a registered user in the system.

    Attributes:
        id: Unique user identifier.
        name: Display name.
        email: Primary email address.
        created_at: UTC timestamp of account creation.
    """
    id: str
    name: str
    email: str = ""
    created_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    def is_active(self) -> bool:
        """Return True if the user account is in good standing."""
        return bool(self.email)


class Manager:
    """Handles user lifecycle with thread-safe access.

    The manager coordinates persistence and caching. Inject
    dependencies at construction time.
    """

    def __init__(self, store: UserStore, cache_size: int = 100) -> None:
        self._store = store
        self._cache_size = cache_size

    async def find(self, user_id: str) -> User | None:
        """Find a user by ID; returns None if not found.

        Args:
            user_id: The unique user identifier to look up.

        Returns:
            The User object if found, None otherwise.

        Raises:
            ConnectionError: If the store is unreachable.
        """
        try:
            return await asyncio.wait_for(
                self._store.get(user_id),
                timeout=DEFAULT_TIMEOUT_MS / 1000,
            )
        except asyncio.TimeoutError:
            logger.warning("User lookup timed out for %s", user_id)
            return None

    # Good: @property for computed attributes.
    @property
    def cache_size(self) -> int:
        return self._cache_size

    # Good: Self return type for builder methods.
    def with_cache_size(self, size: int) -> Self:
        self._cache_size = size
        return self


class UserStore:
    """Abstract interface for user persistence."""

    async def get(self, user_id: str) -> User:
        raise NotImplementedError


# Good: Short names in tight scopes.
for i, user in enumerate(active_users):
    if user.is_active():
        process_active_user(user)

# Good: Context managers for deterministic cleanup.
with open("data.txt", encoding="utf-8") as f:
    content = f.read()

# Good: List comprehension when readable.
squared = [x ** 2 for x in numbers if x > 0]

# Good: Walrus operator for assignment expressions (Python 3.8+).
if (n := len(items)) > 10:
    logger.info("Processing %d items", n)

# Good: match/case for pattern matching (Python 3.10+).
match status:
    case 200 | 201:
        handle_success()
    case 400:
        handle_bad_request()
    case 500:
        handle_server_error()
    case _:
        handle_unknown()

# Good: f-strings for string formatting.
message = f"User {user.name} logged in at {timestamp:%Y-%m-%d %H:%M}"

# Good: pathlib over os.path.
config_path = Path(__file__).parent / "config.yaml"

# Good: Explicit exception handling with chaining.
try:
    result = process_data(data)
except ValueError as e:
    logger.error("Invalid data: %s", e)
    raise DataProcessingError("Cannot process input") from e

# Good: Exception groups (Python 3.11+).
try:
    async with asyncio.TaskGroup() as tg:
        tg.create_task(fetch(url1))
        tg.create_task(fetch(url2))
except* ConnectionError as eg:
    logger.error("Connection failed for %d URLs", len(eg.exceptions))

# Good: Use dataclasses for simple data containers.
@dataclass(slots=True)
class Config:
    host: str
    port: int = 8080
    debug: bool = False
```
