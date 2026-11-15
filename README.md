# agent-guidance

A shared set of coding guidelines and reusable skills for Codex and Claude Code. [AGENTS.md](AGENTS.md) describes when to use each workflow, and [skills/](skills/) contains the skills maintained here.

## Install

The installer runs on Windows, macOS, and Linux. It needs Git and PowerShell 7.4 or later (`pwsh`). On macOS, use the [PowerShell installer or Homebrew](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-macos). On Windows, run the commands in PowerShell 7.

```sh
git clone https://github.com/boba-pipi/agent-guidance.git
cd agent-guidance
pwsh -NoProfile -File ./scripts/install.ps1
```

The installer fetches the pinned Git submodules and installs one shared copy under `~/.agent-guidance/skills`. It links each skill into `~/.agents/skills` for Codex and the Claude Code profile's `skills` directory. The installer uses junctions on Windows and symbolic links on macOS and Linux. It honors `CLAUDE_CONFIG_DIR` when set and otherwise uses `~/.claude/skills`. Existing same-name skill directories are kept and reported. Restart the agents to refresh their skill lists.

UI UX Pro Max uses Python 3 for its local design search. Its search scripts and data are installed with the skill.

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
| Review and verify code | `quality-review` |
| Delegate to the other local agent | `agent-delegate` |
| Design tests | `test-design` |
| Design and review interfaces | `ui-ux-pro-max` |
| Unity development | `unity-guideline` with `csharp-guidelines` |
| Other language and engine conventions | C++, C#, Go, Godot, and Python |

Invoke `quality-review` for a project-wide review or name a module to inspect. Use `learn` followed by the topic you want to understand.

`agent-delegate` uses Claude Code from Codex and Codex from Claude Code. `review` provides a read-only second opinion, `test` runs the supplied command in a detached snapshot and sends its output to the other agent, and `code` returns changes from an isolated snapshot for the caller to review. The other CLI needs to be installed and authenticated. The installer retires its own links for the previous review skills and reports manually installed copies.

## Upstream skills

Git submodules pin the exact upstream revisions. The installer selects the following skill folders and includes their supporting files.

| Source | Installed skills |
| --- | --- |
| [Matt Pocock's skills](https://github.com/mattpocock/skills) | `codebase-design`, `diagnosing-bugs`, `grill-me`, `grilling` |
| [Ponytail](https://github.com/DietrichGebert/ponytail) | `ponytail` |
| [Addy Osmani's agent skills](https://github.com/addyosmani/agent-skills) | `performance-optimization` |
| [Teimurjan's skills](https://github.com/teimurjan/skills) | `perf-engineering` |
| [UI UX Pro Max](https://www.uupm.cc/) | [`ui-ux-pro-max`](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) |

When reviewing an upstream update, check out the desired revision in that submodule and commit the new pin in this repository. Check each upstream repository for its license terms. See [LICENSE](LICENSE) for the material maintained here.
