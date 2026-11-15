---
name: agent-delegate
description: Use the other local agent for an independent review, test result analysis, or a scoped implementation. Routes Codex to Claude Code and Claude Code to Codex. Use when the user requests cross-agent work or quality-review calls for a second opinion.
---

# Agent Delegate

Delegate one bounded task. Pass `-From codex` in Codex and `-From claude` in Claude Code. A child completes its assigned task directly. Keep integration and the final verdict with the calling agent. Respect repository source-sharing rules, including the destination model provider. Honor requests to use only the current agent.

## Choose the mode

- **Review.** Prepare a small UTF-8 packet outside the project with the expected behavior, review criteria, source or diff with line numbers, relevant callers and observed results. Include relevant staged, unstaged and untracked work. Omit secrets, unrelated files and earlier verdicts. Claude Code can also read approved files in `-ReviewDirectory`. The launcher gives both agents the same adversarial criteria and read-only evidence. Confirm or disprove each finding on the original project. Report scope, model and effort. Use at most one follow-up within the calling workflow's budget.
- **Test.** Supply the exact executable and arguments as `-TestCommandJson`, a JSON array of strings. The launcher runs that command with normal host permissions inside a detached snapshot. Use an existing trusted test command. It records the exit code and streams and sends the other agent a bounded log excerpt to interpret. The launcher flags tracked changes and new non-ignored files in the snapshot. Apply `test-design` when designing or changing tests.
- **Code.** Describe the behavior, allowed paths, acceptance checks and pertinent project rules. The agent edits a detached snapshot. Claude Code uses scoped file tools. Codex can run focused checks in its workspace-write sandbox, and the launcher records those commands and their exit codes. Inspect the returned diff, including added files, and verify it before integration. The calling agent retains control of integration, commits and pushes.

## Run the launcher

Use PowerShell 7.4 or later. Set `$runner` to the absolute path of `scripts/invoke-delegate.ps1` in this skill and `$hostAgent` to the current host's name.

```powershell
& $runner -From $hostAgent -Mode review -PromptPath $packet
& $runner -From $hostAgent -Mode test -PromptPath $packet -Repository $repo -TestCommandJson '["go","test","./..."]'
& $runner -From $hostAgent -Mode code -PromptPath $packet -Repository $repo -Revision HEAD
```

The test and code modes take one committed revision, defaulting to `HEAD`, and return JSON with the revision, snapshot path and agent summary. Use the named revision's actual contents when scoping the task. Snapshots remain available for inspection and later cleanup. Repos requiring submodules or dependencies may need a project-specific test command to set them up.

For review, use the newest eligible model at `xhigh` or `max`. The launcher checks Codex's local catalog. For Claude Code, inspect the configured provider with `& $runner -From codex -InspectRoute`. Use the configured model for compatible or cloud routes. On direct Anthropic, verify the current eligible model from CLI or vendor evidence and pass `-Model` as needed. Keep provider overrides and credentials on their intended route. Report authentication, model or sandbox failures using the recorded evidence.
