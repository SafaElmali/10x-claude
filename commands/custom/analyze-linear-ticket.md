---
description: Handle Linear tasks by fetching issue details and comments via Linear MCP, then implementing changes locally. Requires Linear MCP server.
argument-hint: <linear-issue-id>
---

# Linear Task Handler (MCP-gated)

Handle a Linear task safely and consistently by fetching issue details + comments, validating alignment, and implementing changes **without** committing/pushing or commenting on the task.

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
  - Get transcript via: `npx tsx bin/-/loom-transcriptor.ts <loom-url>`
  - Use transcript to capture reproduction steps, expected behavior, and edge cases.

### 5) Handle the issue (implementation)

- Reproduce/understand the problem from the gathered data.
- Implement changes locally:
  - Update code
  - Add/adjust tests if applicable
  - Ensure build/lint/test pass (as applicable)
- Summarize what changed and where.

## Output expectations

When done, provide:
- What you found (root cause)
- What you changed (file-by-file summary)
- How to verify (steps)
- Any risks / follow-ups

## DO NOT DO (Strict)

- **Do not commit or push** anything to git.
- **Do not comment** anything on the Linear task.
