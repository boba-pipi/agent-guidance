---
name: claude-check
description: Run an independent Claude Code review from Codex when asked for adversarial verification, a second model, or a cross-check of a material design, change, bug finding, or performance claim.
---

# Claude Check

Use this from Codex. In Claude Code, route the request to `codex-check`.

1. Prepare the smallest useful evidence packet with the requested behavior, exact diff or source, relevant callers, schema, tests, and observed results. Include relevant in-scope changes. Exclude secrets, production data, unrelated files, and earlier reviewers' opinions. Honor source-sharing restrictions. For source inspection, export approved files into a curated temporary directory. Use a fixed commit when concurrent edits would change the evidence.
2. Identify the configured backend before selecting a model or handling authentication. Set `$runner` to the absolute path of `scripts/invoke-review.ps1` in the installed `codex-check` skill directory. Claude Code can use direct Anthropic, an Anthropic-compatible provider such as DeepSeek, or a cloud provider. Inspect the route without inference:

   ```powershell
   pwsh -NoProfile -File $runner -Reviewer claude -InspectRoute
   ```

   The launcher reports the backend, endpoint host, model, configuration source, effort, and credential category. It uses inherited connection values and fills missing values from Claude user settings, including `CLAUDE_CONFIG_DIR`. Credentials stay in memory and go only to the intended backend. Resolve project or managed connection overrides when the intended route depends on them.
3. Choose a model within that backend. For direct Anthropic, honor an explicit user model or establish the newest eligible native model from current CLI/vendor evidence. For compatible and cloud providers, start with the configured model. Preserve explicit model pins and report any necessary provider-supported session override. Preserve alias mappings and context qualifiers such as `[1M]`. Default to `xhigh` or `max`, using an eligible configured effort. Honor an explicit user effort override when the task permits it. Explain an applicable project requirement and obtain the user's exception before conflicting with it.
4. Use Claude Code's native file-inspection workflow and preserve the supplied review request without expanding its scope. The launcher writes the request into an isolated directory and enables `Read`, `Glob`, and `Grep`. CLI restricted mode confines file access to that directory, and strict MCP configuration keeps external connectors out of the review. Pass a curated source directory when the packet refers to actual files:

   ```powershell
   pwsh -NoProfile -File $runner -Reviewer claude -PromptPath $packet -ReviewDirectory $reviewDir
   ```

   `ReviewDirectory` must contain only approved evidence. Without it, the launcher creates a temporary directory containing the packet. Use `-Model` and `-Effort` for explicit session overrides. The CLI receives the selected effort consistently through its flag and environment.
5. Verify the review response, actual evidence inspection, and model-usage metadata. The launcher accepts native read-only file calls, tolerates omission of the `[1M]` context suffix in reported model names, and rejects different identities. A successful process exit supplies no review verdict by itself. Raw provider tool-call text such as DSML, unsupported tool executions or unresolved requests, empty responses, and uninspected evidence are failures. An explicitly denied tool request can be followed by a valid file-based review. Report the configured endpoint and provider-reported model separately.
6. Diagnose the actual selected route. Compatible and cloud backends use their own credentials. A stale Anthropic account login can coexist with a working third-party backend. Request Anthropic OAuth only after an actual direct-Anthropic account-authentication failure. For unexpected behavior, compare a minimal native CLI call using the same backend and a neutral file read before adding flags or changing configuration. Treat a timeout as incomplete verification.
7. Verify reported issues locally. Mark each `confirmed`, `plausible`, or `rejected` with supporting evidence. Fix confirmed, in-scope issues when authorized and run focused checks. Allow one follow-up review of material fixes or disputed findings with fresh evidence, within the parent review budget.
8. Report Claude Code as the tool, the backend/endpoint, requested and reported models, effort, verified findings, reviewed scope, and gaps. A no-finding verdict applies to the supplied evidence.
