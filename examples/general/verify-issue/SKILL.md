---
name: verify-issue
description: "Adjudicate a reported issue against the CURRENT code and deliver a verdict backed by evidence you produced this session — never from memory, never by paraphrasing the issue back. Decides four separate things: is the claim TRUE, is it STALE (already fixed), is the WORDING/diagnosis correct, and does it still MATTER. Distinguishes a real code defect from an environmental or flaky-upstream failure, and from a real symptom with a wrong stated cause. Use when the user asks to check / verify / validate / adjudicate an issue or bug report, asks whether an issue is still valid or already fixed, says 'verify it against the code not from memory', or pastes an issue number and asks for a verdict.\n\n<example>\nContext: The user wants an old issue triaged before planning work.\nuser: \"can you check the issue #1042 and verify it against the code not from memory, and tell me your verdict?\"\nassistant: \"I'll run the verify-issue skill: read the issue verbatim, decompose it into falsifiable claims, reproduce each against current HEAD, and give a verdict with the commands behind it.\"\n<commentary>\nThe canonical invocation — adjudicate a specific issue against the real code.\n</commentary>\n</example>\n\n<example>\nContext: A stale backlog.\nuser: \"is #880 still a thing or did we already fix it?\"\nassistant: \"I'll verify #880 against the current code — checking by content, not by commit message, since a squash merge would hide the fix.\"\n<commentary>\nStaleness check is one of this skill's four gates.\n</commentary>\n</example>\n\n<example>\nContext: An issue whose description may be misdiagnosed.\nuser: \"/verify-issue 1207 — I think the title is wrong\"\nassistant: \"I'll check whether the symptom reproduces and separately whether the stated cause, file and symbol are accurate, then propose corrected wording.\"\n<commentary>\nA real symptom with a wrong stated mechanism is its own verdict, not a plain 'confirmed'.\n</commentary>\n</example>"
version: 1.0.0
---

# Verify an issue against the code — adjudicate, don't agree

You are adjudicating a **claim**. The issue is the accusation, not the evidence. Your job is to reach a verdict that
would survive someone re-running your commands.

**The failure mode this skill exists to prevent:** reading a well-written issue, recognising the shape of it, and
confirming it — because it sounds right, because it was filed by someone competent, or because you half-remember the
code. A confident wrong verdict is worse than no verdict: it sends someone to fix code that is already fixed, or
closes a live defect.

Every sentence of your verdict must trace to a command you ran or a file you read **in this session**, quoted with a
`path:line`. If you cannot produce the evidence, you do not have the finding.

---

## The four questions — answer each separately

The user's underlying ask is never just "true or false". It is four independent questions, and they have different
answers surprisingly often:

| # | Question | Failure if skipped |
|---|---|---|
| 1 | **Is the claim true?** Does the described behaviour actually occur? | You fix a phantom |
| 2 | **Is it stale?** Was it true once and already fixed? | You re-fix fixed code, or reopen churn |
| 3 | **Is the wording right?** Are the stated cause, file, symbol, and scope accurate? | The fixer is sent to the wrong place |
| 4 | **Does it still matter?** Is the affected path still reachable and used? | You spend effort on dead code |

A single verdict line that does not distinguish these is a failed run of this skill.

---

## Workflow

### 0. Read the issue verbatim — and its history

```bash
gh issue view <N> --json number,title,body,state,createdAt,updatedAt,closedAt,labels,author,comments
```

Capture: the exact claim, every file/symbol/line it names, the version or commit it was filed against, and **every
comment** — a later comment often already contains the fix, a repro, or a correction the title never got.

Note the **age**. An issue filed against code that has since been rewritten is a staleness candidate before you read
a line of source.

### 1. Decompose into falsifiable claims

Rewrite the issue as a numbered list of assertions that can each be individually proven or disproven. Vague prose
becomes checkable propositions:

> "The catalog loader is slow and sometimes returns the wrong variable."

becomes

1. `Catalog()` takes more than X ms on a warm cache.
2. `get_variable(ds, v)` can return a `Variable` whose `nc_variable` is not the one `ds/v` declares.
3. (2) happens via the code path the issue names.

You will verify **each** claim. A partially-true issue is the most common real outcome, and you cannot report it
without this decomposition.

### 2. Locate the code as it is NOW

Never trust the paths in the issue — files move, symbols get renamed, repos get restructured.

```bash
git -C <repo> log --oneline -3                       # where are we
grep -rn "<symbol>" <repo> --include=*.py            # does the named symbol still exist
git -C <repo> log --oneline -1 -- <path>             # when did the named file last change
```

If a named path or symbol no longer exists, that is a finding in itself (question 3) — resolve where the code went
before concluding anything about behaviour.

### 3. Reproduce on current HEAD — the decisive step

**This is the step the whole skill exists for.** Prefer, in order:

1. **Run it.** A script, a REPL snippet, a targeted `pytest -k`, a CLI invocation. Actually execute the path.
2. **A failing/passing test.** Write the smallest test that would fail if the claim is true; run it both ways.
3. **Read the code path end to end** — only when execution is impossible (credentials, hardware, an external
   service). Say explicitly that you could not execute, and what you read instead.

Reproduction beats inference every time. If the claim is reproducible on demand, *reproduce it* — do not reason about
it from the source. One command settles what an hour of reading argues about.

When the claim involves an external service or upstream data, **query the live source** rather than judging by the
shape of a name or an id. Things that look malformed are routinely real.

### 4. Staleness — check by CONTENT, not by commit message

To decide "was this already fixed":

```bash
git -C <repo> log --oneline --all -S"<distinctive code string>" -- <path>   # when did this text appear/vanish
git -C <repo> show <ref>:<path> | grep -n "<guard or fix>"                  # is the fix present at that ref
```

- **A squash merge makes the branch's commit hashes non-ancestors of `main`.** Searching for the branch's commits
  will find nothing even though the fix shipped. Verify the fix by the **content** it introduced.
- A commit message claiming a fix is not proof the fix is present — code gets reverted, rebased away, or lost in a
  conflict resolution. Read the file at HEAD.
- Conversely, absence of a fix commit is not proof the bug is live — the behaviour may have changed as a side effect
  of an unrelated refactor. Go back to step 3 and reproduce.

### 5. Audit the wording and the diagnosis

An issue can be **right about the symptom and wrong about everything else**. Check each independently:

- **Stated cause** — does the mechanism the issue blames actually produce the symptom? Prove the causal link, or
  report that the symptom is real but the cause is unverified.
- **Named location** — do the file, function, and line still contain what the issue says?
- **Quoted evidence** — line numbers drift, counts drift (`"~134 datasets"`), and log excerpts age. Re-derive them.
- **Scope words** — "always", "every", "all backends", "silently". Test the quantifier: a bug that fires on one code
  path is not "always", and the difference changes the priority.
- **Title accuracy** — the title is what people triage from. If it names the wrong component, say so and propose a
  replacement.

### 6. Is it a code defect at all?

Before confirming, rule out the classes that look identical from a log but need entirely different responses:

- **Environmental** — an upstream outage, a rate limit or throttle, expired credentials, a flaky third-party
  endpoint, a network block. Real failure, no code to fix. *Check whether the same failure occurs on an untouched
  baseline.*
- **Configuration / data** — a stale cache, a bad local config, unaccepted licence, missing token.
- **Test-harness artefact** — an unfaithful stub, an ordering dependency, a fixture that does not model the real
  client.
- **Working as designed** — the behaviour is intentional and documented; the issue is a disagreement with the design,
  which is a discussion, not a bug.

When the reported failure is masked by error handling (a swallowed exception, a default that turns an error into an
empty result), the *reported* symptom and the *actual* cause can look unrelated. Follow the error path to its origin
before naming a cause.

### 7. Check for duplicates and supersession

```bash
gh issue list --state all --search "<key terms>" --json number,title,state
gh pr list --state all --search "<key terms>" --json number,title,state
```

An open issue already fixed by a merged PR, or duplicated by a newer better-written issue, changes the recommended
action even when the claim is true.

---

## Verdict taxonomy

Pick exactly one, and say what should happen to the issue:

| Verdict | Meaning | Recommended action |
|---|---|---|
| **CONFIRMED** | Reproduces on current HEAD, as described | Keep open; ready to fix |
| **CONFIRMED — MISDIAGNOSED** | Symptom is real; stated cause / file / scope is wrong | Keep open, **retitle/rewrite** with the real mechanism |
| **CONFIRMED — NARROWER** | Real, but only under conditions the issue overstates | Keep open, narrow the scope wording |
| **ALREADY FIXED** | Was true; fixed at `<commit/content>` | Close, citing what fixed it |
| **PARTIALLY STALE** | Some claims fixed, others still live | Close the fixed parts in the body; keep the live ones |
| **NOT REPRODUCIBLE** | Cannot make it happen; say exactly what you tried | Ask for a repro; do not close silently |
| **INVALID** | The premise is factually wrong | Close with the evidence |
| **NOT A CODE DEFECT** | Environmental / config / harness / by design | Close or convert; name the real cause |
| **NEEDS INFO** | Under-specified in a way no amount of code reading settles | Ask the specific question that would decide it |

State **confidence** and what would change your mind. A verdict you cannot argue against is usually one you did not
test hard enough.

---

## Output format

```markdown
## Verdict: <VERDICT> — <one-line reason>

**Issue #N** — "<title>"  ·  filed <date>  ·  repo at `<short-sha>`

### Claims checked
| # | Claim | Result | Evidence |
|---|-------|--------|----------|
| 1 | <falsifiable assertion> | true / false / stale | `path:line`, or the command + its output |

### Reproduction
<the exact command run and its real output — or an explicit statement that execution was impossible, why, and
what was read instead>

### Wording audit
- <each inaccuracy in the title/body/cause/scope, with the correction>
- <or: "the description matches the code as written">

### Recommended action
<close / retitle / narrow / keep open / need info> — and the concrete next step.

### Confidence
<high/medium/low> — <what would change this verdict>
```

Keep it short. A verdict, the claims table, and the evidence. No restating the issue back to the user.

---

## Anti-patterns — how this goes wrong

- **Agreeing with a well-written issue.** Fluency is not evidence. A precise, confident, plausible issue is exactly
  the one you are most likely to rubber-stamp.
- **Answering from memory of the codebase.** Even if you edited that file an hour ago, re-read it. It may have moved
  under a merge.
- **Trusting a commit message over the file.** "fix: X" in the log is a claim, not a state. Read the file at HEAD.
- **Judging an upstream id, name, or value by its shape.** A weird-looking dataset id, a truncated-looking name, an
  implausible unit — query the live source before calling it malformed.
- **Guessing at an external rule or tool's semantics.** If a linter, analyzer, or service is central to the claim,
  fetch its actual rule definition. Two guesses cost more than one lookup.
- **Stopping at the first plausible cause.** Verify the cause *produces* the symptom; a coincidence sitting near the
  failure is not a diagnosis.
- **Reporting "confirmed" for a partially-true issue.** Decompose first, or you will over- or under-state it.
- **Blaming the change in front of you.** When a failure appears alongside recent work, check whether it also occurs
  on an untouched baseline before attributing it.
- **A verdict with no falsifiable evidence.** If nothing in your answer could be re-run, you produced an opinion.

---

## Boundaries

- **Read-only by default.** This skill investigates and reports; it does not fix the issue, and it does not edit,
  close, retitle, or comment on the issue unless the user explicitly asks. Recommend the action, let them take it.
- Writing a **throwaway repro script or a temporary test** is in scope — that is how you produce evidence. Put it in
  a scratch location and do not commit it.
- If verifying requires something you must not do (use a credential you cannot see, hit a paid or rate-limited
  service, run a destructive command), **stop and say so** rather than substituting inference for proof.
