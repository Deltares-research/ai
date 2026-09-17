---
# FILE TYPE : Path-specific custom instructions (second example)
# LOCATION  : <repo-root>/.github/instructions/NAME.instructions.md
# TRIGGER   : Auto-attached when a Markdown file is edited or referenced.
# SCOPE     : Only files matching `applyTo` — here, all Markdown docs.
applyTo: "**/*.md"
description: "Style rules for documentation and Markdown"
---

# Documentation style

Apply these rules whenever working on Markdown files.

- Write in the second person ("you"), present tense, active voice.
- Wrap prose at 120 characters, breaking on word boundaries.
- Use sentence case for headings, not Title Case.
- Show a runnable example before explaining options in prose.
- Prefer a short table over a long bulleted list when comparing things.
