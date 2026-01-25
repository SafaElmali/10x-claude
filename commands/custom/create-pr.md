---
description: Create a git branch for a Linear task, commit changes, and create a PR. Linear MCP optional.
argument-hint: <linear-task-id>
---

# Linear Task Branch + PR Creator

Create a correctly named git branch for a Linear task, prepare a conventional commit message, and create a PR based on git diff vs `origin/main` and optional Linear context.

## Arguments

- `TICKET_ID` (required): The Linear issue key (e.g., `WEB-2041`)

## Workflow

### 1) Gather Context (Linear MCP optional)

1. **Check if Linear MCP is available**
2. If Linear MCP available:
   - Use `get_issue` for task details
   - Use `list_comments` for additional context
   - Note the task title and description for PR enrichment
3. If Linear MCP NOT available:
   - Continue with git diff only
   - Use the `TICKET_ID` argument as-is
   - Tell user: "Linear MCP not available; proceeding with git diff context only."

### 2) Branch Setup

1. **Check current branch:**
   - Run `git branch --show-current`
   - If NOT on `main` or `master`, use the current branch (skip creation)
   - If on `main` or `master`, create a new branch

2. **Get username for branch name:**
   - Use safa
   <!-- - Run `git config user.name` or parse from `git config user.email` (part before @)
   - Convert to lowercase kebab-case (e.g., "John Doe" → "john-doe") -->

3. **Create branch (only if on main/master):**
   - Format: `<username>/<ticket-id>/<desc>`
   - `<desc>` = short kebab-case summary from Linear title or git diff
   - Example: `john-doe/WEB-2041/add-product-page`
   - Run: `git checkout -b <branch-name>`

### 3) Lint & Test Gate

**This step is mandatory. Do not skip.**

1. **Run JS/TS linter:**
   - Run `pnpm lint`
   - If linter fails: fix errors or **STOP** and tell user
   - Do not proceed until lint passes

2. **Run Ruby linter (for changed Ruby files):**
   - Get changed Ruby files: `git diff origin/main --name-only | grep '\.rb$'`
   - If Ruby files changed:
     - Run `bundle exec rubocop <changed_ruby_files> --format simple`
     - If rubocop fails: fix errors (usually line length, indentation)
     - Re-run until rubocop passes
   - Common fixes: break long lines, fix indentation

3. **Check for changed spec files:**
   - Run `git diff origin/main --name-only | grep '_spec\.rb$'`
   - If spec files were changed:
     - Run those specific specs: `bundle exec rspec <changed_spec_files>`
     - If specs fail: **STOP** and tell user to fix failing tests
     - Retry running specs after user makes fixes until they pass
   - If no spec files changed: skip test step

### 4) Commit Changes

1. **Inspect changes:**
   - `git status`
   - `git diff`
   - `git diff --cached` (if staged)

2. **Commit message format (exact):**

```
<type>: <TICKET_ID> <description>
```

Where `<type>` is one of: `feat`, `fix`, `refactor`

Examples:
- `feat: WEB-2041 Add product page`
- `fix: WEB-1234 Resolve null pointer in user service`
- `refactor: WEB-5678 Extract payment logic to service`

3. **Stage and commit:**
   - `git add <files>` (be selective, don't add unrelated files)
   - `git commit -m "<message>"`

### 5) Create PR

1. **Compare branch changes vs main:**
   - Use `git diff origin/main...HEAD` to understand the delta

2. **Read PR template if it exists:**
   - `.github/PULL_REQUEST_TEMPLATE.md`

3. **Push the branch:**
   - `git push -u origin <branch-name>`

4. **Create PR using `gh pr create`:**
   - Title: `<type>: [<TICKET_ID>] <task-title>`
   - Body following the PR template structure

**Guidelines for description content:**
- Start with a concise paragraph explaining what was wrong/missing and what changed to solve it
- Follow with a few bullets summarizing the key changes
- If Linear context available: align narrative with issue description
- If Linear context NOT available: derive summary from git diff

## DO NOT DO (Strict)

- **Do not comment** on the Linear task
- **Do not skip** the lint step
- **Do not run** the full test suite (only changed spec files)
- **Do not push** if lint fails
- **Do not include** "Claude" or "Co-Authored-By" in commit messages
- **Do not add** "Generated with Claude Code" or similar attribution to PR descriptions
- **Do not use** `git commit --amend` or `git push --force` — always create new commits
