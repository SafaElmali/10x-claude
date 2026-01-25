---
description: Summarize code changes in PM-friendly language and post to Linear ticket as a comment.
argument-hint: <linear-ticket-id>
---

# Summarize Changes

Summarize code changes in non-technical, PM-friendly language and post as a comment to a Linear ticket.

## Arguments

- `TICKET_ID` (required): The Linear issue key (e.g., `WEB-1234`)

## Instructions

### 1. Get the Ticket Context

Use `mcp__plugin_linear_linear__get_issue` to fetch the ticket title and description. This helps understand what problem was being solved.

### 2. Gather the Changes

Determine what changes were made. Try these in order:

```bash
# Option 1: Unstaged/staged changes (work in progress)
git diff HEAD --stat

# Option 2: If no uncommitted changes, check commits on current branch vs main
git log main..HEAD --oneline
git diff main..HEAD --stat

# Option 3: If on main, check the most recent commit
git show --stat HEAD
```

Read the actual diff to understand what changed.

### 3. Write the Summary

Create a summary following these rules:

**DO:**
- Focus on WHAT changed from a user/product perspective
- Use simple, non-technical language a PM would use
- Highlight user-facing changes (new buttons, settings, features)
- Keep it concise (3-5 bullet points max)
- Mention where users can find new features in the UI

**DON'T:**
- Mention file names, function names, or code details
- Use technical jargon (API, migration, refactor, component, etc.)
- List every small change
- Include implementation details
- Say things like "added a column" or "updated the controller"

### 4. Format the Summary

```markdown
## Changes Summary

[One sentence overview of what was accomplished]

**What's new:**
- [User-facing change 1]
- [User-facing change 2]
- [User-facing change 3]
```

### 5. Post to Linear

Use `mcp__plugin_linear_linear__create_comment` to post:

```
issueId: <TICKET_ID>
body: <formatted_summary>
```

### 6. Confirm

Tell the user the summary was posted and show them what was written.

## Example Transformations

### Example 1

**Technical diff:**
> Added `review_request_email_enabled` boolean to `product_review_settings`. Updated worker to check flag. Added Switch component in settings UI.

**PM-friendly summary:**
> Added a new toggle in Product Settings > Reviews that lets sellers turn off automatic review request emails. When disabled, customers won't receive emails asking to review their purchase. The setting is on by default.

### Example 2

**Technical diff:**
> Fixed N+1 query in EnrollmentVerifier by adding includes(:user). Added index on enrollments table.

**PM-friendly summary:**
> Fixed a performance issue that was causing the enrollment verification page to load slowly for publications with many subscribers.

### Example 3

**Technical diff:**
> Added multi-split branch visualization to automations canvas. New SplitBranchNode component with percentage display.

**PM-friendly summary:**
> Automations now visually show split branches on the canvas, making it easier to see how subscribers are divided between different paths.
