---
name: quality-review
description: Review project architecture, code design and organization, correctness, performance, tests, and style. Review the current project by default or a specified module, branch, or diff. Use for quality audits and requests to review and improve code in bounded iterations.
---

# Quality Review

Invoking `quality-review` without a narrower target reviews the current project across all areas below. Honor a requested target or focus. A review request yields findings in chat. A request to fix or optimize authorizes scoped edits.

## Establish the scope

Read the applicable repository and directory rules for the files under review, including `AGENTS.md` or `CLAUDE.md` where present. Use the language guidance and the stated behavior or requirements.

- For a whole-project review, map the project structure and trace its main workflows. Then examine representative entry points and the most consequential or frequently changed modules.
- For a PR, branch, or diff, establish the comparison and summarize what the change is intended to do. Start with the changed code and follow affected callers, configuration, or tests when they can confirm or disprove a concern. Report issues the change introduces or worsens, including regressions that surface outside the diff.

## Apply specialist criteria during review

Read and apply the relevant specialist skills before reaching conclusions about each area in scope. Choose them by the behavior, workload, or risk being reviewed. Scope the evidence to what can change a conclusion. If a specialist skill is unavailable, apply its criteria described below using the evidence available. Report checks left incomplete.

- **Project architecture.** Use `codebase-design` to inspect module and layer boundaries, dependency direction, and ownership of rules and state across key workflows. Trace representative flows across those boundaries and check whether the current split makes changes local or spreads them across modules.
- **Code design and organization.** Use `codebase-design` inside key modules to inspect class and function responsibilities, interfaces and their callers, duplicated rules, and unnecessary indirection. Show how an issue affects a caller, a test, or a likely change.
- **Performance.** Choose `performance-optimization` for latency, throughput, queries, or end-to-end workflows. Choose `perf-engineering` for CPU, allocations, memory, cache, or scaling. Pick a representative workload, such as the dominant workflow or a high-frequency path. Use existing measurements if they match that workload and revision, or collect a focused baseline and profile when feasible. Tie a finding to a measured cost, regression, or missed budget. Static concerns can guide profiling. When evidence is unavailable, state what remains unverified and what to measure. Report tested load and results even when no target exists.
- **Correctness.** Trace actual call paths, failure branches, persisted data, and compatibility. Check trust boundaries and authorization when relevant. Check observable invariants such as round trips or idempotence where relevant. Use `diagnosing-bugs` for nontrivial failures or suspected defects that need reproduction.
- **Tests.** Use `test-design` to check whether the suite exercises important contracts, failure paths, and regressions. Run relevant existing tests when feasible. Name the behavior at risk and the missing assertion or test level. If edits are in scope, add a focused test when it closes a concrete gap.
- **Code style.** Apply the project rules and corresponding language skill. Use configured lint or format checks when feasible. Cite the applicable rule and the affected code for material violations.

## Adversarial verification

Run one independent cross-check by default after the initial review when the matching review CLI and skill are available, including when the initial review found no issues. Use `claude-check` from Codex and `codex-check` from Claude Code. In a review-and-improve task, do this before selecting fixes. Pass the relevant criteria and scoped evidence so the reviewer can look for missed issues and challenge assumptions independently.

Honor a local-only request and applicable source-sharing rules. A cross-check reviewer completes its assigned review without delegating it. Verify returned findings locally before including them as confirmed. Report whether the check ran, the model and effort, and any coverage limits or blocker. Use a second check only for material fixes or disputed findings. Limit the review to two external checks total.

## Verify and report findings

Challenge each candidate finding, including those from the cross-check. Reproduce the issue or trace a concrete scenario from its trigger to its impact. For a test gap, identify the behavior and the faulty implementation that the suite would let pass. Apply the measured-evidence requirement to performance and cite the scoped rule for convention findings. Update conclusions when a focused check supplies stronger evidence.

Lead with actionable findings in order of impact. Combine reports with the same root cause. Give each finding a severity, source location, triggering condition, evidence, impact, and a way to verify the fix. In a whole-project review, distinguish architecture findings from code design findings. Briefly state the paths, tests, and workloads reviewed and any material gaps in evidence, including unresolved risks that need a specific check.

## Improve and verify

1. Rank confirmed issues by impact. Select a small batch when edits are in scope. Use the same specialist criteria to choose and verify a fix, and use `ponytail` to keep changes focused.
2. Recheck each finding with the evidence that established it. Trace the same callers and preserved contracts for design changes. Verify the original failure no longer occurs for bug fixes. Repeat performance measurements under the same workload and conditions. Re-audit changed paths and relevant callers for regressions. Revert only your own changes that fail verification or add complexity without demonstrated benefit.
3. Count every edit-and-verify attempt as a round. Use at most two rounds by default. Use a third only when the second leaves a confirmed, material issue with a realistic, verifiable fix. Respect a lower user-specified cap. The hard cap is three.
4. Stop when no confirmed actionable issue remains, the performance target is met with no other material finding, or further progress needs evidence or access you lack. Report what changed, test or benchmark results, and remaining or unverified issues.
