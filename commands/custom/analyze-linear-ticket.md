---
description: Handle Linear tasks by fetching issue details and comments via Linear MCP, then implementing changes locally. Requires Linear MCP server.
argument-hint: <linear-issue-id> [--auto]
---

# Linear Task Handler (MCP-gated)

Handle a Linear task safely and consistently by fetching issue details + comments, validating alignment, and implementing changes **without** committing/pushing or commenting on the task.

## Arguments

Parse the input for:
- `TICKET_ID` - Linear ticket ID (e.g., WEB-1234) - REQUIRED
- `--auto` - Skip the plan approval gate and proceed automatically

## Hard Gate (Must do before anything)

1. **Check available MCP servers**.
2. If **no Linear MCP** is available:
   - **STOP immediately**
   - Tell the user: "No Linear MCP found; I can't proceed."

## Workflow

### 1) Fetch issue details

Use Linear MCP method: `get_issue`

Capture:
- Title
- Description
- Status / priority
- Labels
- Assignee
- Links (Figma, Loom, files, screenshots, Slack threads)
- Any acceptance criteria or expected behavior

### 2) List comments

Use Linear MCP method: `list_comments`

Extract:
- Extra requirements
- Clarifications
- Design/product notes
- Links (Figma/Loom/files/Slack threads)
- Any contradictions vs description

### 3) Consistency check (Stop condition)

Compare **issue description** vs **comments**:
- If they differ in a way that suggests an ongoing external thread (e.g., Slack-driven change, evolving requirements) or create ambiguity about what to build:
  - **STOP**
  - Tell the user exactly what differs and ask them to resolve/confirm.

### 4) Linked resources handling

Process links in this priority:

#### 4.1 File links (if provided)
- If user shares file links, assume changes likely relate to those files.
- Inspect those files first.
- Still do a quick repo-wide check to confirm scope and avoid missing related code.

#### 4.2 Slack thread link
- If the task includes a **Slack thread link** (in the issue or comments):
  1. **Verify Slack MCP exists**.
  2. If **Slack MCP is not available**:
     - **STOP** and report: "Slack MCP not available; can't read the Slack thread."
  3. If available:
     - Open the Slack thread and **read all messages in the thread** (including attachments/snippets where accessible).
     - Extract:
       - Any requirement changes vs the issue description/comments
       - Repro steps, expected behavior, edge cases
       - Any "final decision" message (often near the end)
       - Links to assets (Figma, screenshots, logs)
     - Then **re-run the consistency check**:
       - If Slack messages introduce new requirements or contradict the Linear issue/comments in a way that creates ambiguity:
         - **STOP**
         - Report the exact differences and ask the user to resolve/confirm what to implement.

#### 4.3 Figma link
- If the task includes a Figma link:
  - Verify **Figma MCP** exists.
  - If not available:
    - **STOP** and report: "Figma MCP not available; can't extract design details."
  - If available:
    - Fetch relevant frames/specs and extract UI requirements.

#### 4.4 Screenshot
- If a screenshot is included:
  - Analyze it to understand expected vs actual behavior.
  - Note visible UI states, errors, copy, layout issues, and any environment hints.

#### 4.5 Loom video
- If a Loom link is included:
  - Get transcript via: `npx tsx ~/bin/loom-transcriptor.ts <loom-url>`
  - Use transcript to capture reproduction steps, expected behavior, and edge cases.

### 5) Task analysis & agent selection

After gathering all context, analyze what needs to be built:

#### 5.1 Scope identification

Use Glob and Grep to identify files likely to change based on:
- Keywords from the ticket (component names, API endpoints, etc.)
- File paths mentioned in description/comments
- Related code patterns

Categorize the scope:
- **UI-only**: Changes to React components, CSS, styling, client-side logic
- **Backend-only**: API routes, database queries, server-side logic, migrations
- **Full-stack**: Both UI and backend changes required

#### 5.2 Agent selection

Based on scope, select the appropriate agent:

| Scope | Agent |
|-------|-------|
| UI/CSS/React components only | `frontend-developer` |
| API/DB/backend logic only | `backend-developer` |
| Both UI + backend | `fullstack-developer` |

#### 5.3 Task breakdown

Break the ticket into 3-7 specific implementation tasks:
- Order tasks logically (dependencies first)
- Be specific about what each task accomplishes
- Include test/verification steps if applicable

### 6) Plan approval gate

**If `--auto` flag is present:** Skip directly to Phase 7 (Spawn agent) without waiting for approval. Display the plan but proceed immediately.

**Otherwise:** Present the implementation plan to the user and **WAIT for explicit approval** before proceeding.

Display the plan in this format:

```
## {TICKET_ID} - Implementation Plan

**Problem:** {one sentence summary of the issue}
**Solution:** {one sentence description of the approach}

### Tasks
1. {Task 1 - specific action}
2. {Task 2 - specific action}
3. {Task 3 - specific action}
...

### Agent: {frontend-developer | backend-developer | fullstack-developer}
**Reasoning:** {why this agent was selected based on the scope}

### Files likely to change:
- {file path 1}
- {file path 2}
- {file path 3}
...

---
**Approve this plan? (y/n/adjust)**
```

Wait for user response:
- **y / yes / approve**: Proceed to spawn agent
- **n / no**: Stop and ask what should change
- **adjust / other feedback**: Modify plan based on feedback, re-present

### 7) Spawn agent

Once approved, use the **Task tool** to spawn the selected agent:

**Task tool parameters:**
- `subagent_type`: The selected agent (`frontend-developer`, `backend-developer`, or `fullstack-developer`)
- `description`: `Implement {TICKET_ID}`
- `prompt`: Include ALL gathered context in a structured format:

```
# Task: {TICKET_ID} - {Title}

## Problem Statement
{Description from Linear ticket}

## Acceptance Criteria
{Extracted acceptance criteria from description/comments}

## Additional Context
{Summary of linked resources - Slack thread, Figma specs, Loom transcript, screenshots}

## Files Likely to Change
{List of file paths identified during analysis}

## Implementation Tasks
1. {Task 1}
2. {Task 2}
3. {Task 3}
...

## Important Notes
- Do NOT commit or push changes
- Run lint/tests as applicable
- Report what changed and how to verify
```

The agent will:
- Implement the changes locally
- Run lint/tests as applicable
- **NOT commit or push** (use `/beehiiv:create-pr` separately after reviewing changes)

### 8) Summary

After the agent completes, provide:
- What was implemented (file-by-file summary)
- How to verify the changes work
- Any risks or follow-ups identified
- Reminder: Use `/beehiiv:create-pr` to commit and create PR when ready

## Output expectations

When done, provide:
- What you found (root cause / requirements understood)
- What was implemented (file-by-file summary)
- How to verify (steps)
- Any risks / follow-ups
- Next step: `/beehiiv:create-pr {TICKET_ID}` to create PR

## DO NOT DO (Strict)

- **Do not commit or push** anything to git.
- **Do not comment** anything on the Linear task.
- **Do not skip the approval gate** unless `--auto` flag was provided.
