---
description: Review a GitHub pull request by fetching diff, checking out the branch locally, and producing a structured review. Requires gh CLI.
argument-hint: <pr-url>
---

# PR Review Agent (GitHub PR URL -> Diff + Local Checkout + Structured Review)

Given a **GitHub PR URL**, fetch diff, check out the PR branch locally, review every change, and write a structured review file ending in **APPROVE** or **REQUEST CHANGES**.

Assumes a Unix shell with `gh` (GitHub CLI) and `git` installed.

## Inputs

- **PR URL**: `<pr-url>`

## Workflow

### 1) Resolve PR metadata and number

Extract the PR number and basic metadata using GitHub CLI:

```bash
PR_URL="<pr-url>"
PR_NUMBER="$(printf "%s" "$PR_URL" | sed -E 's#^.*/pull/([0-9]+).*$#\1#')"

# Fail fast if PR_NUMBER couldn't be parsed
if [ -z "$PR_NUMBER" ] || ! printf "%s" "$PR_NUMBER" | grep -Eq '^[0-9]+$'; then
  echo "Error: Could not parse PR number from URL: $PR_URL" >&2
  exit 1
fi

# Get core metadata
gh pr view "$PR_URL" --json number,title,author,baseRefName,headRefName,headRepository \
  --template '{{.number}} {{.title}} {{.author.login}} {{.baseRefName}} {{.headRefName}} {{if .headRepository}}{{.headRepository.nameWithOwner}}{{end}}' \
  | awk '{print}' > /tmp/pr_meta.txt
```

### 2) Save the diff

Create the diffs directory and write the unified diff:

```bash
mkdir -p "_ai/diffs"
gh pr diff "$PR_URL" --patch > "_ai/diffs/${PR_NUMBER}.diff"
```

- If the diff is empty:
  - Note: **"No changes."**
  - Still produce a review file and end with **APPROVE**.

### 3) Fetch and checkout the PR branch

Prefer fetching from origin then checking out the PR's head ref. If that fails (e.g., forks), fallback to `gh pr checkout`.

```bash
HEAD_REF="$(gh pr view "$PR_URL" --json headRefName --jq .headRefName)"

# Try via origin first
if git fetch origin "$HEAD_REF"; then
  git checkout "$HEAD_REF"
else
  # Fallback: handles forks or remote naming differences
  gh pr checkout "$PR_URL"
fi

# Check working tree cleanliness
git status --porcelain
```

- After checkout:
  - If `git status --porcelain` is not empty, list untracked/modified files in the review notes.

### 4) Review scope and priorities

Review **all changes** in the diff, focusing on:

- **Correctness & Bugs:** logic errors, off-by-one, nil/null handling, race conditions, exception flow.
- **Security:** injection, unsafe deserialization, unvalidated input, secrets, authz/authn checks, SSRF, CSRF, XSS, SQLi, path traversal, command injection.
- **Performance:** N+1 queries, unnecessary loops, large allocations, blocking I/O, repeated computations, inefficient queries, excessive renders.
- **Concurrency:** data races, non-atomic updates, deadlocks, improper locking/awaiting, async pitfalls.
- **API Contracts:** type safety, input/output validation, backward compatibility, deprecations.
- **Error Handling & Observability:** clear errors, correct status codes, logging levels, metrics, retries, fallbacks.
- **Testing:** coverage for new logic + edge cases, determinism, flaky patterns.
- **Maintainability:** readability, naming, duplication, separation of concerns.
- **Security/Privacy by Default:** least privilege, safe defaults, PII handling, secrets not in logs.
- **Docs & Migrations:** safe/reversible migrations, README/CHANGELOG updates when needed.

Ignore generated files and lockfiles unless clearly problematic.

### 5) Produce the review file

Write a Markdown file at: `_ai/reviews/<pr-number>.md`

Use this exact structure and headings:

```md
# PR Review — <title> (PR #<pr-number>)
**Author:** <author>
**Base:** <baseRefName> -> **Head:** <headRefName>
**Reviewed At:** <YYYY-MM-DD HH:MM local time>

## Summary
- Briefly summarize what the PR attempts to do, based on title/description/diff.
- Note any areas of risk or modules heavily impacted.

## Overall Assessment
- One short paragraph on general code quality, scope, and readiness.

## Diff Stats
- Files changed: <n>
- Insertions: <n>, Deletions: <n>
- Notable directories touched: <list>

## High-Risk Findings
List only **Critical/Major** issues here with bullets. Example item format:
- **[Severity: Critical]** `<path/to/file.ext>:<line>` — Short title
  Why it's a problem (1-3 sentences).
  **Suggestion:** Provide a revised snippet or a concrete fix.

## Comments
List all comments in a numbered format, grouped by category. Each comment should follow this structure:

### 1. <simple summary>

**File:** `<path/to/file.ext>`

**Severity:** <Critical | Major | Minor>

**Line:** <line number or range>

<Observation and explanation of the issue>

**Suggestion:** <Concrete fix, code snippet, or patch>

(Repeat for all comments, incrementing the number. Group related comments by category when possible.)

## Tests & Tooling
- Do new or changed behaviors have tests? If missing, specify exact tests to add.
- Note any linter/type errors found (if applicable).
- Mention performance checks or micro-bench ideas when relevant.

## Documentation & Migrations
- If public API/behavior changes, specify needed doc updates.
- If DB or system migrations exist, assess safety, downtime, and rollback steps.

## Final Decision

**Status:** <APPROVE | REQUEST CHANGES>

**Rationale:** 2-5 sentences explaining the decision, explicitly referencing any High-Risk Findings.
If REQUEST CHANGES, enumerate the required items to move to APPROVE.
```

### 6) Heuristics for decision

- **APPROVE** if:
  - No Critical/Major issues remain, and
  - Minor issues are mostly nits or safe to follow up later.

- **REQUEST CHANGES** if any:
  - Security risk not addressed,
  - Breaking changes without migration/notice,
  - Failing/absent tests for critical logic,
  - Significant correctness or performance concerns,
  - Unclear/unsafe migrations.

### 7) Output (deliverables)

- `_ai/diffs/<pr-number>.diff` — unified diff
- `_ai/reviews/<pr-number>.md` — structured review with **APPROVE** or **REQUEST CHANGES**

### 8) Failure handling

If any command fails (e.g., `gh` auth, branch fetch/checkout), stop and clearly report:
- Which step failed,
- The exact command run and its stderr,
- What to try next (examples):
  - `gh auth login`
  - check `git remote -v`
  - use `gh pr checkout "$PR_URL"` for forks/permissions
