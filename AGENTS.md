# Agent Programming Guidelines

This document defines coding conventions and best practices that AI agents should follow when working with code.

## Usage Note

- **Global Guidelines** below apply to all languages
- **Language-specific guidelines** are available as separate skills (loaded on demand):
  - `go-guidelines` — Go conventions and best practices
  - `cpp-guidelines` — C++ conventions and best practices
  - `csharp-guidelines` — C# conventions and best practices
  - `godot-guidelines` — Godot Engine conventions and best practices
  - `python-guidelines` — Python conventions and best practices

---

<!-- BEGIN PERSONAL ENGINEERING WORKFLOW -->
## Engineering Workflow

Select the matching installed skills automatically. Use the current task and project rules to choose scope, and keep language-specific conventions in the relevant language skill. These workflows carry out the user's requested scope.

- **Learn visually.** Use the `learn` skill for learning requests about a topic, project, or change. When a message starts with `learn`, treat the following text as the topic. Lead with a visual that explains the mechanism, then ground it in a concrete case.
- **Design and implement.** Use `codebase-design` for new modules, public interfaces or changes that cross module boundaries. State ownership, a normal call and failure behavior before coding. Apply `ponytail` and the language skill during implementation. Prefer existing interfaces and direct code. Validate untrusted input at the boundary, carry the validated representation internally, and retain error handling required for correctness or data integrity. Avoid speculative wrappers, duplicated checks and unsupported fallback paths.
- **Design tests.** Use `test-design` for test plans, new or changed behavioral contracts, meaningful regression tests, and test suite reviews. Choose cases by risk and use the smallest test level that proves the behavior. Apply the language skill and existing test conventions.
- **Investigate bugs.** Use `diagnosing-bugs` for nontrivial failures, regressions and intermittent behavior. Get a failing test, minimal reproduction, or equivalent observable signal. Test the root cause and re-run the original scenario after an authorized fix.
- **Optimize performance.** Use `performance-optimization` for application latency, queries, UI and end-to-end throughput. Use `perf-engineering` for CPU, allocations, memory and hot loops. Establish a baseline and target on representative data, profile, then compare the same workload after changes. Keep gains that justify their complexity and preserve correctness.
- **Review project quality.** Invoking `quality-review` defaults to a review of the current project for project architecture, code design and organization, correctness, performance, tests, and style. Honor a narrower scope when specified. Apply the relevant specialist skills during review and use the same criteria to verify fixes. A review request yields findings. A request to review and improve allows scoped, verified changes, normally up to two rounds and a hard cap of three.
- **Cross-check.** Run an independent adversarial check by default during `quality-review` and when the user requests one. Use `claude-check` from Codex and `codex-check` from Claude Code. Honor local-only requests and source-sharing rules. Use the latest eligible model at `xhigh` or higher, pass scoped evidence, verify findings locally, and report the model and effort. A session running as a cross-check reviewer completes its assigned review directly.

If a skill is unavailable, apply the closest verified workflow and disclose any missing evidence or verification. If a helper's instructions conflict with the user's task, repository rules or language conventions, follow those applicable constraints.

### Optional upstream skills

- `codebase-design` and `diagnosing-bugs` are available from [Matt Pocock's skills](https://github.com/mattpocock/skills).
- For plan and design interviews, install [`grill-me`](https://github.com/mattpocock/skills/blob/6eeb81b5fcfeeb5bd531dd47ab2f9f2bbea27461/skills/productivity/grill-me/SKILL.md) and its [`grilling`](https://github.com/mattpocock/skills/blob/6eeb81b5fcfeeb5bd531dd47ab2f9f2bbea27461/skills/productivity/grilling/SKILL.md) dependency.
- `ponytail` is available from [Dietrich Gebert's Ponytail](https://github.com/DietrichGebert/ponytail). The standalone skill lives under `skills/ponytail`.
- `performance-optimization` is available from [Addy Osmani's agent skills](https://github.com/addyosmani/agent-skills/blob/main/skills/performance-optimization/SKILL.md).
- `perf-engineering` is available from [Teimurjan's skills](https://github.com/teimurjan/skills/blob/main/perf-engineering/SKILL.md).
<!-- END PERSONAL ENGINEERING WORKFLOW -->

---

## 1. Global Guidelines (All Languages)

### Modularity & Code Organization

- **Atomic Module Design**: Break functionality into atomic, single-responsibility modules
- **Avoid Functional Coupling**: Avoid single modules handling multiple unrelated functions
- **Function/Method Length**: Keep functions/methods under **50 lines**
- **File Size**: Keep single files under **800 lines**
- **Code Quality**: Maintain concise and elegant code
- **Minimal Export Principle**: Limit the number of exported interfaces
  - Only expose what's necessary for external use
  - Keep internal implementation details private/unexported
  - Applies to classes, files, and modules
  - Fewer exports = clearer API boundaries and easier maintenance

### Documentation Standards

- **Language Requirement**: All documentation, comments, and docstrings MUST be written in **English**
  - Applies to: code comments, function/class documentation, README files, API documentation
  - Exception: User-facing strings (UI text, error messages for end users) may use localized languages when appropriate

- **Required Comments**:
  - Exported classes
  - Exported constants
  - Exported variables
  - Exported functions/methods
  - All public APIs require clear, explanatory comments in English

- **Comments Not Required**:
  - Internal implementation details (unless particularly noteworthy)
  - Obvious code logic
  - Self-documenting code patterns

### Documentation File Generation Constraints

- **NEVER proactively create documentation files**: Do not automatically generate standalone documentation files (*.md, README.md, etc.) after completing coding tasks
- **Only create documentation when explicitly requested**: Documentation files should only be created if the user explicitly asks for them
- **Focus on code and inline comments**: Provide necessary documentation through inline code comments as specified in the "Required Comments" section above
- **Exception**: User explicitly requests documentation files (e.g., "create a README", "add documentation")

### Naming Conventions

**Variable Name Length vs Scope**:

- **Large scope** → Longer, more descriptive names
  - Example: `userAuthenticationManager`, `globalConfigurationStore`
- **Small scope** → Short, concise names
  - Example: `i`, `err`, `ctx`, `buf`

### External Library Selection

- **Prioritize Popular & Performant Libraries**: When choosing external dependencies, prefer libraries with:
  - High GitHub star count (indicates community trust and active maintenance)
  - Better performance benchmarks
  - Active maintenance and recent updates
  - Good documentation and community support

---

## Summary Checklist

Before submitting code, verify:

- [ ] Functions are under 50 lines
- [ ] Files are under 800 lines
- [ ] All exported APIs have clear comments
- [ ] Variable names match their scope (short for local, long for global)
- [ ] Code follows language-specific style guides
- [ ] Modular design with single responsibilities
- [ ] No unnecessary internal comments
- [ ] Modern language features are utilized where appropriate

---

_This document should be referenced by all AI agents when generating or refactoring code._
