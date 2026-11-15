---
name: test-design
description: Design, write or review software tests from observable behavior and risk. Use for test plans, test cases, missing coverage, meaningful regressions, and deciding between unit, integration, contract, end-to-end, or property-based tests. Running an existing suite alone does not require this skill.
---

# Test Design

Use the project's language conventions, framework, and existing test entry points. For a plan or test review, report cases and gaps in chat. For implementation or bug fixes, add or adjust tests when required by the task or when existing checks cannot catch a material regression. Preserve the requested scope.

## Derive cases from the contract

1. Find the observable behavior in requirements, public interfaces, caller expectations, schemas, or existing tests. List the expected outcomes and meaningful side effects for normal and failure paths. If a requirement is unresolved, state the assumption or ask about the ambiguity that changes the expected outcome.
2. Check what the current suite already proves. Choose the most consequential distinct failure modes introduced by the change, including compatibility or state integrity when relevant. Name the concrete mistake each proposed case would catch.
3. Choose techniques that fit the behavior:
   - **Input partitions and boundaries:** Choose representative valid and invalid classes. Exercise meaningful limits immediately below, at, or above the threshold where behavior changes.
   - **Decision tables:** If several independent conditions govern a result, map meaningful combinations to outcomes. Remove impossible or redundant cases.
   - **State transitions:** Verify allowed and rejected transitions and their visible effects. Include retry, cancellation, partial failure, or recovery when the contract covers them.
   - **Properties or differential tests:** Use invariants such as round-trip, idempotence, or ordering, or compare with a trusted reference. Use the existing generator or fuzz harness where appropriate. Save a minimized counterexample as a deterministic regression case.
4. Set expected results independently of the code under test. Use a business rule, a hand-checked fixture, a known-good comparison, or an independently computed invariant. Assert returned values and material side effects. Include unchanged persisted state when atomic failure is part of the contract.

## Select the smallest reliable test level

| What must be proved | Test level |
| --- | --- |
| A deterministic rule, transform, or calculation | Unit test through the owning module's observable interface |
| Behavior that depends on a database, transaction, filesystem, serialization, or real wiring | Focused integration test exercising that dependency |
| Compatibility between a producer and consumer | Contract test at their shared interface |
| A critical user journey or a failure visible only through full wiring | A focused end-to-end test |

If two tests catch the same failure, keep the faster and clearer one unless the higher layer proves a separate risk. Favor small fixtures, isolated state, and controlled time and randomness. Use fakes at boundaries the test does not need to prove. Keep a real dependency when its behavior is the thing under test. Avoid sleep-based timing, private method assertions, incidental mock call counts, and broad snapshots that obscure the intended result.

## Check that the tests can fail for the right reason

- For a regression, run the case on the known bad behavior when practical, confirm it fails on the intended assertion, then run it against the fix. `diagnosing-bugs` helps isolate the reproducer. Use `tdd` for an explicitly requested test-first implementation when available.
- When a significant new check has never been seen failing, use a known bad input, prior revision in isolation, or a temporary local mutation when practical. The check should catch the named failure rather than a setup error. A passing suite alone does not establish test sensitivity.
- Run the narrow suite first. Run broader checks when contracts or shared dependencies changed. For a timing or resource budget, use the performance skills and a reproducible benchmark. Record commands, outcomes, and material gaps. Treat coverage as a signal for missing behaviors, not a target by itself.

## Example: atomic CSV import

Use an integration test with a valid first row and invalid second row. Call the import entry point, assert that the reported row is 2, and verify through the real persistence boundary that neither row was committed. This proves atomic behavior for invalid input, even when the implementation validates all rows before writing. If write-time rollback is a separate requirement, force a write failure after one successful write inside the real transaction and assert that the persisted state is unchanged. Add a successful import case if the suite does not already prove that valid rows commit and produce the expected count.
