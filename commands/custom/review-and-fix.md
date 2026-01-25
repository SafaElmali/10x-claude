---
description: Comprehensive code review with auto-fix using 6 specialized agents. Run after implementation, before creating PRs.
---

# Review and Fix

Perform comprehensive code review using specialized agents, then auto-fix issues before PR creation.

## Workflow

### 1) Capture Changes

1. **Get all changes (staged + unstaged):**
   - Run `git diff HEAD` to capture all uncommitted changes (both staged and unstaged)
   - If empty, run `git diff origin/main...HEAD` to check committed but unpushed changes
   - If still no changes, inform the user: "No changes to review."

2. **List changed files:**
   - Run `git diff HEAD --name-only` to get list of modified files
   - Note file types (Ruby, TypeScript, etc.) for context

### 2) Lint First (Fast Fail)

**Run lint before launching agents to catch simple issues quickly:**

1. **JS/TS lint:** Run `pnpm lint`
2. **Ruby lint:** For changed Ruby files, run `bundle exec rubocop <files> --format simple`
3. If lint fails:
   - Show lint errors to user
   - Ask: "Fix lint errors before full review, or continue anyway?"
   - If user wants to fix first: **STOP** and let them fix
   - If user wants to continue: proceed but note lint issues

### 3) Launch Specialized Review Agents

Launch all 6 pr-review-toolkit agents **in parallel** using the Task tool:

| Agent | Focus Area |
|-------|------------|
| `pr-review-toolkit:code-reviewer` | Bugs, security vulnerabilities, CLAUDE.md compliance |
| `pr-review-toolkit:silent-failure-hunter` | Error handling, catch blocks, silent failures |
| `pr-review-toolkit:type-design-analyzer` | Type safety, invariants, encapsulation |
| `pr-review-toolkit:pr-test-analyzer` | Test coverage gaps |
| `pr-review-toolkit:comment-analyzer` | Comment accuracy vs actual code |
| `pr-review-toolkit:code-simplifier` | Overly complex code that can be simplified |

For each agent, provide:
- The git diff output
- Context about what files were changed
- Request they return findings with severity levels

### 4) Aggregate Findings

Collect all agent findings and categorize by severity:

**CRITICAL (must fix before PR):**
- Security vulnerabilities
- Crash-causing bugs
- Silent failures that swallow errors
- Data corruption risks

**IMPORTANT (should fix):**
- Logic bugs
- Type safety issues
- Missing error handling
- Inadequate test coverage for new code

**SUGGESTIONS (optional):**
- Code simplification opportunities
- Comment improvements
- Minor style issues

### 5) Auto-Fix Issues

Fix all **CRITICAL** and **IMPORTANT** issues:

1. Apply fixes one by one
2. After each fix, verify it doesn't break syntax
3. If a fix is unclear or risky, ask the user before applying
4. Track what was fixed for the final report

### 6) Verify Fixes

After all fixes are applied:

1. **Run JS/TS lint:** `pnpm lint`
   - If lint fails on fixed code, adjust the fix
   - Do not leave lint errors from your fixes

2. **Run Ruby lint:** For changed Ruby files, run `bundle exec rubocop <files> --format simple`
   - Fix any line length (max 120 chars) or indentation issues
   - Do not leave rubocop offenses

3. **Check for changed spec files:**
   - Run `git diff HEAD --name-only | grep '_spec\.rb$'`
   - If spec files were modified: run those specific specs
   - If specs fail: report which tests fail, attempt to fix

### 7) Re-Review (if needed)

If significant fixes were applied:
- Run a focused re-review on the fixed code only
- Maximum 2 review iterations to prevent infinite loops
- Only re-check the specific issues that were fixed

### 8) Final Report

Present a summary to the user:

```
## Review Summary

### Fixed Issues
- [CRITICAL] Fixed SQL injection in user query (src/api/users.ts:45)
- [IMPORTANT] Added error handling for network failures (src/services/api.ts:102)

### Remaining Suggestions (optional to address)
- [SUGGESTION] Consider extracting validation logic to separate function

### Review Stats
- Agents run: 6
- Issues found: X
- Issues fixed: Y
- Review iterations: Z
- Lint status: passing
```

### 9) Update PR Body (if major changes)

If **major changes** were made during review (new methods, logic changes, architectural fixes):

1. **Check if PR exists:**
   ```bash
   gh pr view --json number,body 2>/dev/null
   ```

2. **If PR exists and major changes were made:**
   - Get current PR body
   - Append a "## Review Changes" section summarizing what was fixed
   - Update PR body:
   ```bash
   gh pr edit <PR_NUMBER> --body "<updated_body>"
   ```

3. **What counts as major changes:**
   - New methods or functions added
   - Logic flow changes
   - Security fixes
   - New test cases added
   - NOT: lint fixes, formatting, minor refactors

## DO NOT DO (Strict)

- **Do not commit** any changes - leave that to `/create-pr`
- **Do not run** the full test suite (only changed spec files)
- **Do not fix** SUGGESTIONS automatically - only report them
- **Do not loop** more than 2 review iterations
- **Do not leave** lint errors from your own fixes
