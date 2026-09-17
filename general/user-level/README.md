# User-level (personal) instructions — where they go

Personal instructions apply to **you** across **every** repository, and are **not**
committed to any project. Where you put them depends on which Copilot client you use.

## VS Code

Personal instructions live in your **user profile**, not in a repo. Create them from
Copilot Chat:

1. Open the Chat view.
2. Open the **Configure Chat** (gear) menu → **Instructions** → **New instruction file**.
3. Choose **User Data Folder** as the location (not the workspace).

They sync across your machines via **Settings Sync**. The example in
[`copilot-instructions.md`](copilot-instructions.md) shows the kind of content that
belongs here.

## GitHub.com and JetBrains

Set personal instructions in the Copilot settings of that client / on GitHub.com under
your Copilot preferences. Same idea: they follow your account, not a repo.

## Copilot CLI

The CLI reads personal instructions from your home directory:

- `~/.copilot/copilot-instructions.md` — always-on personal instructions
- `~/.copilot/instructions/**/*.instructions.md` — path-scoped personal instructions

## Priority reminder

When instructions conflict, **personal wins**:

```
personal  >  path-scoped (.instructions.md)  >  repo-wide (copilot-instructions.md)  >  AGENTS.md  >  organization
```
