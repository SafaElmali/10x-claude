---
description: Create a git branch for a Linear task, prepare commit messages, and generate PR descriptions. Requires Linear MCP server.
argument-hint: <linear-task-id>
---

# Linear Task Branch + PR Description Writer (MCP-aware)

Create a correctly named git branch for a Linear task, prepare a conventional commit message (without pushing), and generate a PR title + description file based on git diff vs `origin/main` and Linear context.

## Hard Gate (Must do before anything)

1. **Check available MCP servers**.
2. If **no Linear MCP** is available:
   - **STOP immediately**
   - Tell the user: "No Linear MCP found; I can't proceed."

## Workflow

### 1) Create branch

1. Determine:
   - `<task-id>` from the Linear issue key (e.g., `WEB-2041`)
   - `<desc>` as a short, kebab-case summary (e.g., `add-product-page`)
2. Create branch in this format:
   - `safa/<task-id>/<desc>`
3. Run:
   - `git checkout -b <branch-name>`

### 2) Prepare commit message (do not push)

1. Inspect changes:
   - `git status`
   - `git diff`
   - `git diff --cached` (if staged)
2. Write a commit message following conventional prefixes:
   - `feat`, `fix`, or `refactor`
3. Commit message format (exact):

```md
(feat | fix | refactor): <task-id> <commit message>

feat: WEB-2041 Add product page
```

4. You may create commits locally, but:
   - **Never push**
   - If unsure whether to commit yet, still produce the correct commit message text.

### 3) Gather Linear context

- Use Linear MCP:
  - `get_issue` for task details
  - `list_comments` for additional context
- Validate alignment:
  - If issue description and comments conflict in a way that indicates requirements are still evolving (e.g., Slack thread divergence):
    - **STOP**
    - Explain the mismatch and request clarification from the user.

### 4) Write PR title + description file

1. Compare branch changes vs main:
   - Use `git diff origin/main...HEAD` to understand the delta.
2. Read PR template:
   - `.github/PULL_REQUEST_TEMPLATE.md`
3. Create PR title + description using this exact output template (no extra commentary):
   - Also **add the commit title** to the PR description file.
4. Write the output to:
   - `_ai/pr-descriptions/<task-id>-<desc>.md`

Template (must match exactly):

```md
[<task-id>](link): <task-title>

{{
    read this file and write pr desc by this template
    .github/PULL_REQUEST_TEMPLATE.md
}}

In description explain the issue first if it was an issue, then explain how we solved it.


Guidelines for description content:

Start with a concise paragraph explaining:

What was wrong / missing (the issue)

What changed to solve it

Follow with a few bullets summarizing the key changes.

Ensure the narrative aligns with both Linear context and actual git diff.
```

### 5) Maintain local Linear ticket notes

1. Ensure a ticket note exists:
   - Directory: `_ai/linear-tickets/`

2. If there is no related markdown file for this ticket:
   - Create: `_ai/linear-tickets/<task-id>-<desc>.md`
   - Include:
     - A short description of the issue
     - What actions should be taken / what was implemented

3. If a related ticket file exists:
   - Update it as needed based on new findings.

### 6) Summary

- Create a short summary of what was done.
- If there is a .md file under `_ai/linear-tickets` for this ticket:
  - Append a new `## Summary` section (or add a dated/iterative summary section) with the latest summary.
- Keep it brief and practical.

## DO NOT DO (Strict)

- **Do not push** anything to git.
- **Do not comment** on the Linear task.
