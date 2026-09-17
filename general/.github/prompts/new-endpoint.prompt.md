---
# FILE TYPE : Prompt file (reusable, user-invoked task)
# LOCATION  : <repo-root>/.github/prompts/NAME.prompt.md
# TRIGGER   : NOT automatic. Run it on demand by typing `/new-endpoint`
#             in Copilot Chat (or Command Palette -> "Chat: Run Prompt").
# SCOPE     : Runs only when you invoke it. Think "slash command".
# NOTE      : Prompt files are primarily a VS Code Copilot feature.
description: "Scaffold a new API endpoint with tests"
mode: agent
argument-hint: "<resource name>, e.g. 'orders'"
---

Create a new API endpoint for the resource: `${input:resource}`.

Do the following:

1. Add the route handler following the patterns already used in this project.
2. Validate the request input and return clear errors on bad input.
3. Add tests covering the happy path and at least one failure case.
4. Update any relevant documentation.

Ask me before adding new dependencies. Show the plan before writing code.
