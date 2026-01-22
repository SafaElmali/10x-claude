---
description: Create a git branch for a Linear task, commit changes, and create a PR. Requires Linear MCP server.
argument-hint: <linear-task-id>
---

# Linear Task Branch + PR Creator (MCP-aware)

Create a correctly named git branch for a Linear task, prepare a conventional commit message, and create a PR based on git diff vs `origin/main` and Linear context.

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
   - `<username>/<task-id>/<desc>` (e.g., `john/WEB-2041/add-product-page`)
3. Run:
   - `git checkout -b <branch-name>`

### 2) Commit changes

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

4. Stage and commit changes locally.

### 3) Gather Linear context

- Use Linear MCP:
  - `get_issue` for task details
  - `list_comments` for additional context
- Validate alignment:
  - If issue description and comments conflict in a way that indicates requirements are still evolving (e.g., Slack thread divergence):
    - **STOP**
    - Explain the mismatch and request clarification from the user.

### 4) Create PR

1. Compare branch changes vs main:
   - Use `git diff origin/main...HEAD` to understand the delta.
2. Read PR template if it exists:
   - `.github/PULL_REQUEST_TEMPLATE.md`
3. Push the branch:
   - `git push -u origin <branch-name>`
4. Create the PR using `gh pr create` with:
   - Title: `[<task-id>] <task-title>`
   - Body following the PR template structure

Guidelines for description content:
- Start with a concise paragraph explaining what was wrong/missing (the issue) and what changed to solve it
- Follow with a few bullets summarizing the key changes
- Ensure the narrative aligns with both Linear context and actual git diff

## DO NOT DO (Strict)

- **Do not comment** on the Linear task.
