---
description: Comprehensive code review with auto-fix using 6 specialized agents. Run after implementation, before creating PRs.
---

# Review and Fix

Perform comprehensive code review using specialized agents, then auto-fix issues before PR creation.

## Workflow

### 1) Capture Changes

Run `git diff` to capture all uncommitted changes. If there are no changes, check for staged changes with `git diff --cached`. If still no changes, inform the user there's nothing to review.

### 2) Launch Specialized Review Agents

Launch all 6 pr-review-toolkit agents **in parallel** using the Task tool to review the changes:

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

### 3) Aggregate Findings

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

### 4) Auto-Fix Issues

Fix all **CRITICAL** and **IMPORTANT** issues automatically:
- Apply fixes one by one
- Ensure each fix doesn't break the build
- Run tests after fixes if a test runner is available

### 5) Re-Review (if needed)

If fixes were applied:
- Run a focused re-review on the fixed code
- Maximum 2 review iterations to prevent infinite loops
- Only re-check the specific issues that were fixed

### 6) Final Report

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
```

## Important Notes

- **Do not commit** any changes - leave that to /create-pr
- If a fix is unclear or risky, ask the user before applying
- If build/tests fail after a fix, revert that specific fix and report it
- Focus on substantive issues, not style nitpicks
