---
name: code-review
description: Reviews code from a pull request (PR) on GitHub.
---

# Code Review Skill
Use the code review skill when the user requests a code review. The user's request could include a PR number.
If only a PR number is provided, assume the user wants to review a PR from the current repository.

## Jira MCP
If needed, more context can be retrieved from the corresponding issue in Jira.
The jira skill can be used to access information on Jira.

## GitHub MCP
The PR can be accessed using the GitHub MCP server. Provide your review in a separate file called `review.md`.

## Problems
If you are unable to access the GitHub MCP server, or the Jira MCP (when needed), stop the review and ask the user how to proceed.

## The review
The review should be written in Markdown and include a summary of the changes made in the PR.

The focus of the review should be on:
- Whether the code changes fix the corresponding Jira issue (if one exists).
- Whether any bugs or errors are introduced.
- Whether the code is sufficiently tested, or whether useful tests are missing.
- Whether functionality was accidentally removed or disconnected during the refactor.
- Whether integrations, registrations, import/export paths, or public APIs were changed in a way that may cause regressions.
- Whether the new implementation preserves important old behavior where backward compatibility is expected.

Do not stop after listing only the strongest 2-3 findings. Continue reviewing until the main changed subsystems and high-risk paths have been inspected.

Organize findings into the following categories when applicable:
1. Confirmed defects/regressions
2. Likely risks / needs verification
3. Missing tests / weak coverage
4. Non-blocking maintainability or design concerns
5. Existing unrelated bugs (separate section, if relevant)

Each finding should include:
- severity
- confidence level (`confirmed`, `high suspicion`, `moderate suspicion`, or `non-blocking concern`)
- why it matters
- the relevant files/symbols
- whether the problem is proven from code inspection or inferred as a risk

At the end of the review, explicitly state whether:
- the findings are intended as a high-confidence shortlist,
- or the findings are intended to be a broader inventory of both confirmed issues and likely risks.

## Additional context
- We are moving away from NHibernate and are moving towards saving to files instead. We still need to be able to load
old project files, but there is no need to save to NHibernate anymore.
- The review should be written in Markdown.
- The review should focus on changes made. If, by chance, a bug is found in existing code, let us know in a separate section.
- Only add Mermaid charts and diagrams when they add value. Don't add charts that are not helpful.

