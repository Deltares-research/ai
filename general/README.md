# GitHub Copilot instructions — a showcase

A hands-on tour of the different ways to give GitHub Copilot instructions. Every file in
this folder is a working example with a header comment explaining **what it is**, **where
it lives**, and **how it's triggered**. Browse the files alongside this guide.

> This showcase covers the two levels you'll use day to day — **repository-level** files
> (committed, shared with the team) and **user-level** files (personal, follow you across
> repos). Organization-wide instructions exist too, but are configured in GitHub org
> settings rather than as files, so they're out of scope here.

## The four mechanisms at a glance

| # | Mechanism | File / path | How it's triggered | Scope |
|---|-----------|-------------|--------------------|-------|
| 1 | **Repo-wide instructions** | `.github/copilot-instructions.md` | Always on, every request | Whole repo, everyone |
| 2 | **Path-specific instructions** | `.github/instructions/*.instructions.md` | Auto, when an edited/referenced file matches `applyTo` | Matching files, everyone |
| 3 | **Prompt files** | `.github/prompts/*.prompt.md` | On demand — type `/name` in chat | Only when you invoke it |
| 4 | **Personal instructions** | User profile / `~/.copilot/…` | Always on, for you | You, across all repos |

## 1. Repository-wide instructions — the "house rules"

**File:** [`.github/copilot-instructions.md`](.github/copilot-instructions.md)

The simplest mechanism. Plain Markdown, no frontmatter. Copilot adds it to **every**
request made in this repository. Use it for broad, project-wide conventions that apply
regardless of which file you're touching. It's the Copilot equivalent of an `AGENTS.md`
or `CLAUDE.md`.

**Try this:** open the file, then ask Copilot Chat to write any function — notice it
follows the style rules without you mentioning them.

## 2. Path-specific instructions — scoped by file pattern

**Files:** [`.github/instructions/tests.instructions.md`](.github/instructions/tests.instructions.md)
and [`.github/instructions/docs.instructions.md`](.github/instructions/docs.instructions.md)

These have YAML frontmatter with an **`applyTo`** glob. Copilot attaches them **only**
when the file you're editing or referencing matches the pattern, and combines them with
the repo-wide rules. Great for rules that only make sense for tests, docs, a specific
language, or a specific folder.

Key frontmatter fields:

- `applyTo` — one or more comma-separated globs deciding when the file applies (use `"**"` for everything).
- `description` — shown on hover in the Chat view.

**Try this:** ask Copilot to add a test — the `tests.instructions.md` rules kick in.
Ask it to edit a Markdown file — the `docs.instructions.md` rules kick in instead.

## 3. Prompt files — reusable slash commands

**Files:** [`.github/prompts/new-endpoint.prompt.md`](.github/prompts/new-endpoint.prompt.md)
and [`.github/prompts/review-diff.prompt.md`](.github/prompts/review-diff.prompt.md)

Unlike the first two, prompt files are **not** automatic. They package a repeatable task
you launch yourself by typing **`/name`** in Copilot Chat (the filename is the command
name). Think of them as slash commands.

Useful frontmatter fields:

- `description` — short summary of the task.
- `mode` — `ask`, `agent`, or `plan` (how Copilot should run it).
- `argument-hint` — guidance shown to the user for expected input.
- `model` — optionally pin a model.

**Try this:** in VS Code Copilot Chat, type `/new-endpoint` and give it a resource name.

> **Note:** prompt files are primarily a **VS Code** Copilot feature, and newer
> "Agent Host" sessions are moving toward *agent skills* instead. Repo-wide and
> path-specific instructions are supported the most broadly across clients.

## 4. Personal (user-level) instructions

**Files:** [`user-level/`](user-level/) — see its
[`README.md`](user-level/README.md) for exactly where these go per client.

These are **your** preferences, applied across **every** repository, and never committed
to a project. In VS Code they live in your user profile (synced via Settings Sync); the
Copilot CLI reads them from `~/.copilot/`. Use them for personal working style — not
team conventions.

## Priority order (when instructions conflict)

From highest to lowest:

```
personal  >  path-scoped (.instructions.md)  >  repo-wide (copilot-instructions.md)  >  AGENTS.md  >  organization
```

So a personal rule always wins, and organization defaults sit at the bottom as a
baseline that repos and individuals can override.

## Which client supports what?

Not every mechanism works everywhere. Rough guide:

- **Repo-wide + path-specific** — supported broadly (VS Code, Visual Studio, JetBrains, Xcode, coding agent, code review).
- **Prompt files** — mainly VS Code Copilot Chat.
- **Personal instructions** — GitHub.com, JetBrains, and the CLI (and surfaced in VS Code).

## Sources

- [Adding repository custom instructions](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions)
- [Custom instructions support matrix](https://docs.github.com/en/copilot/reference/custom-instructions-support)
- [VS Code — custom instructions](https://code.visualstudio.com/docs/copilot/customization/custom-instructions)
- [VS Code — prompt files](https://code.visualstudio.com/docs/copilot/customization/prompt-files)
- [github/awesome-copilot — community examples](https://github.com/github/awesome-copilot)
