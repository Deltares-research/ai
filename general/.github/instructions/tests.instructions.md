---
# FILE TYPE : Path-specific custom instructions
# LOCATION  : <repo-root>/.github/instructions/NAME.instructions.md
# TRIGGER   : Auto-attached whenever a file matching `applyTo` is edited or
#             referenced in chat. Combined with the repo-wide instructions.
# SCOPE     : Only files matching the glob(s) in `applyTo`.
applyTo: "**/test_*.py,**/*_test.py,**/tests/**"
description: "Conventions for writing and changing tests"
---

# Test conventions

Apply these rules whenever working on test files.

- Use `pytest` style: plain functions named `test_*`, plain `assert`.
- One behavior per test. The test name states the behavior being verified.
- Follow Arrange / Act / Assert, separated by blank lines.
- Prefer fixtures over setup/teardown boilerplate.
- Test the behavior, not the implementation — avoid asserting on private internals.
- When fixing a bug, add a test that fails before the fix and passes after.
