---
description: Review a GitHub PR with inline comments on specific lines
argument-hint: <pr-number-or-url>
---

# Review PR

Review a GitHub pull request with inline comments on specific lines.

## Arguments

- `$ARGUMENTS` - PR number or URL (e.g., `19495` or full GitHub PR URL)

## Instructions

### 1. Check PR Status

First, verify the PR is open and reviewable:

```bash
gh pr view <PR_NUMBER> --json state -q .state
```

- If state is `MERGED`: Inform user "This PR has already been merged" and stop
- If state is `CLOSED`: Inform user "This PR is closed" and stop
- Only proceed if state is `OPEN`

### 2. Gather Context

Run these commands to understand the current state:

```bash
git branch --show-current
gh repo view --json nameWithOwner -q .nameWithOwner
```

### 3. Fetch PR Information

```bash
gh pr view <PR_NUMBER> --json title,body,state,author,additions,deletions,files,commits
gh pr diff <PR_NUMBER>
```

### 4. Analyze the Code

Review the diff thoroughly and identify:

- **Bugs or logic errors** - Actual issues that could cause problems
- **Type safety improvements** - Missing types, loose types that could be stricter
- **Test coverage gaps** - Missing edge cases, fragile tests
- **Code style issues** - Only if they deviate from project patterns
- **Security concerns** - Input validation, injection risks, etc.

### 5. Categorize Findings

For each issue, determine severity:

- ✅ **What looks good** - Acknowledge well-written code
- 🟡 **Suggestions (non-blocking)** - Improvements that aren't required
- ⚠️ **Potential issues** - Things that might cause problems
- 🔴 **Blockers** - Must be fixed before merge

### 6. Write Comments

Write comments in a **human, conversational tone**:

- Be direct but friendly
- Explain the "why" not just the "what"
- Provide code examples when suggesting changes
- Use backticks for code references
- Keep comments concise

**Bad:** "This should be changed to use a union type."
**Good:** "Consider using a union type for better type safety and autocomplete:"

### 7. Check PR Ownership

Check if the current user is the PR author:

```bash
# Get current GitHub username
CURRENT_USER=$(gh api user -q .login)

# Get PR author
PR_AUTHOR=$(gh pr view <PR_NUMBER> --json author -q .author.login)
```

**If the current user IS the PR author:**
- Do NOT submit the review to GitHub
- Just show the analysis to the user (proceed to step 8)
- Inform them: "Since this is your own PR, I'm showing you the analysis without submitting a review."

**If the current user is NOT the PR author:**
- Proceed to show the summary first (step 8), then ask before submitting (step 9)

### 8. Show Review Summary

**ALWAYS show the user the full review summary BEFORE submitting.** Display:

1. **Summary** - What the PR does (2-3 sentences)
2. **What looks good** - Acknowledge good patterns
3. **Suggestions** - Grouped by severity (with file paths and line numbers)
4. **Verdict** - Approve / Request Changes / Comment

### 9. Submit Review (Only for Non-Owned PRs)

**Only proceed with submission if:**
- The current user is NOT the PR author
- You have shown the summary to the user

Submit as a GitHub review with inline comments.

**Event types:**
- `COMMENT` - Neutral feedback, no blocking (default for most reviews)
- `APPROVE` - Looks good, ready to merge (no blockers found)
- `REQUEST_CHANGES` - Has blockers that must be fixed before merge

**CRITICAL: Getting Line Numbers Correct**

The `line` field in review comments must be the line number in the **new version of the file** (right side of diff), NOT the original file. To find the correct line number:

1. Look at the diff output from `gh pr diff`
2. Find the hunk header (e.g., `@@ -25,6 +25,8 @@`) - the `+25` means new file starts at line 25
3. Count lines from there in the new file (lines starting with `+` or ` `)
4. The line number is the actual line in the new file where you want the comment

Example diff:
```diff
@@ -10,6 +10,8 @@ const MyComponent = () => {
   const [state, setState] = useState(false);
+  const trackEvent = useTrackEvent();  // <- This is line 12 in new file
+
   return <div>...</div>;
```

To comment on the `trackEvent` line, use `"line": 12` (not the diff position).

```bash
# Get repo owner/name
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

# Create review payload
cat << 'EOF' > /tmp/pr_review.json
{
  "body": "<Overall summary - 1-2 sentences>",
  "event": "COMMENT",
  "comments": [
    {
      "path": "path/to/file.ts",
      "line": <line_number_in_new_file>,
      "body": "<Your comment>"
    }
  ]
}
EOF

# Submit review
gh api repos/$REPO/pulls/<PR_NUMBER>/reviews --input /tmp/pr_review.json

# Cleanup temp file
rm -f /tmp/pr_review.json
```

## Comment Style Guide

- Start with context if needed, then the suggestion
- Use code blocks with language hints for examples
- Reference other parts of the codebase when relevant ("like you did in X")
- For nits, prefix with "Nit:"
- Be specific about line numbers when referencing code

## DO NOT DO

- **Do not submit without showing first** - ALWAYS show the review summary to the user before submitting
- **Do not submit reviews on your own PRs** - If you are the PR author, only show the analysis
- **Do not auto-fix code** - This is someone else's PR; suggest changes, don't make them
- **Do not merge the PR** - Only review; let the author decide when to merge
- **Do not approve PRs with blockers** - Use `REQUEST_CHANGES` if there are 🔴 issues
- **Do not leave vague comments** - Be specific about what should change and why

## Usage

```
/review-pr 19495
/review-pr https://github.com/your-org/your-repo/pull/19495
```
