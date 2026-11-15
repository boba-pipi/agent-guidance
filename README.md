# agent-guidance

A shared set of coding guidelines and reusable skills for Codex and Claude Code. [AGENTS.md](AGENTS.md) describes when to use each workflow, and [skills/](skills/) contains the skills maintained here.

## Install

Requirements are Git and PowerShell 7 (`pwsh`). From a terminal:

```sh
git clone https://github.com/boba-pipi/agent-guidance.git
cd agent-guidance
pwsh -NoProfile -File ./scripts/install.ps1
```

The installer fetches the pinned Git submodules and prepares all 17 skills. It installs one shared copy under `~/.agent-guidance/skills` and links each skill into `~/.agents/skills` for Codex and `~/.claude/skills` for Claude Code. Existing same-name skill directories are kept and reported. Restart the agents to refresh their skill lists.

Use [AGENTS.md](AGENTS.md) as project guidance, or merge it into your existing personal guidance. Codex reads `AGENTS.md`. For Claude Code, use `CLAUDE.md` or import the file with `@AGENTS.md` from a `CLAUDE.md` in the same directory.

To update the installed bundle, pull the repository and rerun the installer.

```sh
git pull --ff-only
pwsh -NoProfile -File ./scripts/install.ps1
```

## Skills

| Area | Skills |
| --- | --- |
| Learn a system | `learn` |
| Review and verify code | `quality-review`, `claude-check`, `codex-check` |
| Design tests | `test-design` |
| Language conventions | C++, C#, Go, Godot, and Python |

For example, invoke `quality-review` for a project-wide review or name a module to inspect. Use `learn` followed by the topic you want to understand. Cross-checks use the other agent's CLI and its configured authentication.

## Upstream skills

Git submodules pin the exact upstream revisions. The installer selects the following skill folders and includes their supporting files.

| Source | Installed skills |
| --- | --- |
| [Matt Pocock's skills](https://github.com/mattpocock/skills) | `codebase-design`, `diagnosing-bugs`, `grill-me`, `grilling` |
| [Ponytail](https://github.com/DietrichGebert/ponytail) | `ponytail` |
| [Addy Osmani's agent skills](https://github.com/addyosmani/agent-skills) | `performance-optimization` |
| [Teimurjan's skills](https://github.com/teimurjan/skills) | `perf-engineering` |

When reviewing an upstream update, check out the desired revision in that submodule and commit the new pin in this repository. Check each upstream repository for its license terms. See [LICENSE](LICENSE) for the material maintained here.
