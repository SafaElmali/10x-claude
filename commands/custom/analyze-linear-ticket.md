---
description: Handle Linear tasks by fetching issue details and comments via Linear MCP, then implementing changes locally. Requires Linear MCP server.
argument-hint: <linear-issue-id> [--confirm]
---

# Linear Task Handler

Handle a Linear task by fetching issue details + comments, validating alignment, and implementing changes **without** committing/pushing.

## Arguments

- `TICKET_ID` - Linear ticket ID (e.g., WEB-1234) - REQUIRED
- `--confirm` - Show plan and wait for approval before proceeding (default: auto-proceed)

## Hard Gate

1. Check available MCP servers
2. If **no Linear MCP** available → **STOP** and tell user: "No Linear MCP found; I can't proceed."

## Workflow

### 1) Fetch & Analyze

Use Linear MCP to gather context:
- `get_issue` - Get title, description, status, priority, labels, assignee, acceptance criteria
- `list_comments` - Get clarifications, design notes, extra requirements

**Consistency check:** If description and comments conflict or create ambiguity → **STOP** and ask user to clarify.

### 2) Process linked resources (if any)

If the ticket includes links (Figma, Loom, screenshots, Slack), extract relevant context:
- **Figma:** Use Figma MCP if available to get specs
- **Loom:** Get transcript via `npx tsx ~/bin/loom-transcriptor.ts <url>`
- **Screenshots:** Analyze for expected vs actual behavior
- If an MCP is required but unavailable, note it and continue with available info

### 3) Scope & Agent Selection

Use Glob/Grep to identify files likely to change based on keywords, paths, and patterns.

**Categorize scope:**
- **UI-only:** React components, CSS, client-side logic → `frontend-developer`
- **Backend-only (Node/TS):** API routes, DB queries, TypeScript backend → `backend-developer`
- **Backend-only (Rails):** Ruby/Rails, ActiveRecord, Sidekiq, service objects → `senior-rails-backend-dev`
- **Full-stack:** Both UI and backend → `fullstack-developer`

**Break into 3-7 implementation tasks** ordered by dependencies.

### 4) Plan Approval Gate

**Default:** Display plan briefly and proceed to step 5.

**If `--confirm` flag:** Present plan and **WAIT for approval**:

```
## {TICKET_ID} - Implementation Plan

**Problem:** {one sentence}
**Solution:** {one sentence}

### Tasks
1. {specific action}
2. {specific action}
...

### Agent: {selected agent}
### Files: {list of likely files}

---
**Approve? (y/n/adjust)**
```

- **y/yes:** Proceed
- **n/no:** Stop, ask what to change
- **adjust:** Modify and re-present

### 5) Spawn Agent

Use **Task tool** to spawn the selected agent:
- `subagent_type`: Selected agent
- `description`: `Implement {TICKET_ID}`
- `prompt`: Include all gathered context:

```
# Task: {TICKET_ID} - {Title}

## Problem Statement
{Description}

## Acceptance Criteria
{From description/comments}

## Additional Context
{Figma specs, Loom transcript, screenshots, Slack summary}

## Files Likely to Change
{List}

## Implementation Tasks
1. {Task 1}
2. {Task 2}
...

## Notes
- Do NOT commit or push
- Run lint/tests as applicable
```

### 6) Lint Check (Required)

After agent completes, **always run lint** before finishing:

1. **Run lint:**
   ```bash
   pnpm lint
   ```
2. If lint fails:
   - Fix the lint errors automatically
   - Re-run lint to verify fixes
   - Do not proceed until lint passes

3. **For Ruby files, also run:**
   ```bash
   bundle exec rubocop <changed_ruby_files> --format simple
   ```
   - Fix any offenses before finishing

### 7) Summary

After agent completes and lint passes, provide:
- What was implemented (file-by-file)
- How to verify the changes
- Any risks or follow-ups
- Lint status: passing ✓
- Next step: `/create-pr {TICKET_ID}`

## DO NOT DO

- **Do not commit or push** anything to git
- **Do not comment** on the Linear task
- **Do not wait for approval** unless `--confirm` was provided
