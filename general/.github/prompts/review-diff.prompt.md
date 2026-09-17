---
# FILE TYPE : Prompt file (second example)
# LOCATION  : <repo-root>/.github/prompts/NAME.prompt.md
# TRIGGER   : Type `/review-diff` in Copilot Chat.
description: "Review the current working-tree changes"
mode: ask
---

Review the changes currently in the working tree (the `git diff`).

Focus on, in this order:

1. Correctness bugs and edge cases that would break at runtime.
2. Silent failures — swallowed errors, ignored return values.
3. Missing test coverage for the new or changed behavior.
4. Readability and consistency with the surrounding code.

Report findings most-severe first. For each, give the file, the line, and a
one-sentence explanation of what goes wrong. Do not restate code that is fine.
