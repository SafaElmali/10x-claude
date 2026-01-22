# Review PR

Review a GitHub pull request with inline comments on specific lines.

## Context

- Current branch: !`git branch --show-current`
- Repository: !`gh repo view --json nameWithOwner -q .nameWithOwner`

## Arguments

- `$ARGUMENTS` - PR number or URL (e.g., `19495` or full GitHub PR URL)

## Instructions

### 1. Fetch PR Information

```bash
gh pr view <PR_NUMBER> --json title,body,state,author,additions,deletions,files,commits
gh pr diff <PR_NUMBER>
```

### 2. Analyze the Code

Review the diff thoroughly and identify:

- **Bugs or logic errors** - Actual issues that could cause problems
- **Type safety improvements** - Missing types, loose types that could be stricter
- **Test coverage gaps** - Missing edge cases, fragile tests
- **Code style issues** - Only if they deviate from project patterns
- **Security concerns** - Input validation, injection risks, etc.

### 3. Categorize Findings

For each issue, determine severity:

- ✅ **What looks good** - Acknowledge well-written code
- 🟡 **Suggestions (non-blocking)** - Improvements that aren't required
- ⚠️ **Potential issues** - Things that might cause problems
- 🔴 **Blockers** - Must be fixed before merge

### 4. Write Comments

Write comments in a **human, conversational tone**:

- Be direct but friendly
- Explain the "why" not just the "what"
- Provide code examples when suggesting changes
- Use backticks for code references
- Keep comments concise

**Bad:** "This should be changed to use a union type."
**Good:** "Consider using a union type for better type safety and autocomplete:"

### 5. Submit Review

Submit as a GitHub review with inline comments:

```bash
cat << 'EOF' > /tmp/pr_review.json
{
  "body": "<Overall summary - 1-2 sentences>",
  "event": "COMMENT",
  "comments": [
    {
      "path": "path/to/file.ts",
      "line": <line_number>,
      "body": "<Your comment>"
    }
  ]
}
EOF
gh api repos/{owner}/{repo}/pulls/<PR_NUMBER>/reviews --input /tmp/pr_review.json
```

### 6. Output Summary

Before submitting, show the user:

1. **Summary** - What the PR does (2-3 sentences)
2. **What looks good** - Acknowledge good patterns
3. **Suggestions** - Grouped by severity
4. **Verdict** - Approve / Request Changes / Comment

## Comment Style Guide

- Start with context if needed, then the suggestion
- Use code blocks with language hints for examples
- Reference other parts of the codebase when relevant ("like you did in X")
- For nits, prefix with "Nit:"
- Be specific about line numbers when referencing code

## Usage

```
/review-pr 19495
/review-pr https://github.com/owner/repo/pull/19495
```
