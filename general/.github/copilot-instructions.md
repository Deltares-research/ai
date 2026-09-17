<!--
  FILE TYPE : Repository-wide custom instructions
  LOCATION  : <repo-root>/.github/copilot-instructions.md
  TRIGGER   : Always on. Automatically added to EVERY Copilot request
              made in the context of this repository. No frontmatter.
  SCOPE     : The whole repository.
  ANALOGY   : This is the "house rules" file — the equivalent of an
              AGENTS.md / CLAUDE.md for Copilot.
-->

# Copilot instructions for this project

These instructions apply to every Copilot chat and code-completion request in this
repository. Keep them short and general — put file-type-specific rules in
`.github/instructions/*.instructions.md` instead.

## General coding style

- Write code that reads like the surrounding code: match its naming, structure, and idioms.
- Prefer explicit, readable code over clever one-liners.
- Wrap lines at 100 characters.
- Never swallow errors silently — handle them or let them surface with context.

## Comments and docs

- Comment the "why", not the "what". Don't restate what the code already says.
- Keep public functions documented; keep internal helpers self-explanatory.

## What NOT to do

- Don't introduce a new dependency without a clear reason.
- Don't leave commented-out code or `TODO` placeholders in committed changes.
