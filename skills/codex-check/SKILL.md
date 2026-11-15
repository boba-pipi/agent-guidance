---
name: codex-check
description: Run an independent local Codex CLI review from Claude Code when asked for adversarial verification, a second model, or a cross-check of a material design, change, bug finding, or performance claim.
---

# Codex Check

Use this from Claude Code. In Codex, route the request to `claude-check`.

1. Prepare the smallest review packet that can support a verdict: the requested behavior, invariants, exact diff or source excerpts with file and line numbers, relevant callers/tests, and actual test or benchmark results. Include in-scope staged and unstaged changes and relevant untracked files. Exclude secrets, production data, unrelated files and earlier reviewers' opinions. Respect any repository restrictions on sending source to another model provider.
2. Save the packet as temporary UTF-8 text outside the project. Run the bundled launcher. Set `$runner` to the absolute path of `scripts/invoke-review.ps1` in the installed `codex-check` skill directory. It checks the local model catalog on every run, selects a current general or coding model supporting `xhigh` or higher, and passes the model and effort explicitly. If the user named a model, pass `-Model` to validate it against that catalog. Surface model or authentication failures in the final report.

   ```powershell
   pwsh -NoProfile -File $runner -Reviewer codex -PromptPath $packet
   ```

3. Verify each reported issue against the current source. Mark it `confirmed` if reproduced or traced end to end, `plausible` if evidence is incomplete, or `rejected` with the reason. Fix only confirmed, in-scope issues when edits were requested. Run a focused check for each fix. Allow one follow-up review of material fixes or disputed findings. Use fresh evidence and stay within the parent workflow's review budget.
4. Report the selected model and effort from the launcher, confirmed findings and their evidence, and areas left unchecked. An empty report means no defect was found in the supplied evidence.

The launcher supplies a read-only evidence packet. Give it evidence, not instructions to modify files, call another reviewer, or run attacks.
