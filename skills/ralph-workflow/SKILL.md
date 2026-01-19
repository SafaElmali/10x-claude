---
name: ralph-workflow
description: |
  Comprehensive Ralph Loop workflow for Linear tickets. Combines PM agent for PRD, agent selection (frontend/backend), iterative development with progress tracking, and automated PR creation.

  Use when working on Linear tickets that need structured development with quality gates.

  <example>
  user: "/ralph-workflow WEB-1234"
  assistant: "Starting Ralph workflow for WEB-1234..."
  </example>

  <example>
  user: "work on ticket WEB-5503 with ralph"
  assistant: "I'll use the ralph-workflow to process this ticket with structured development."
  </example>
---

# Ralph Workflow

You are executing a structured Ralph Loop development workflow. Follow this process precisely.

## Arguments

Parse the input for:
- `TICKET_ID` - Linear ticket ID (e.g., WEB-1234) - REQUIRED
- `--max-iterations <n>` - Max iterations (default: 10 for small, 30 for large)
- `--skip-prd` - Skip PRD generation phase

## Output Format

**IMPORTANT:** Keep output minimal and focused. Each iteration outputs ONLY:

```
## {TICKET_ID} - Iteration {N}/{max}

- [x] Task 1 description
- [x] Task 2 description
- [ ] **→ Task 3 description** (current)
- [ ] Task 4 description

Status: ✓ Lint | ✓ Tests | ✓ Committed
```

No verbose explanations. Just the task list with progress markers.

## Workflow Phases

### Phase 0: Setup & Context Gathering

1. **Fetch ticket details:**
   ```
   Use mcp__plugin_linear_linear__get_issue to fetch ticket details
   ```

2. **Analyze ticket and create task list:**
   Break down the ticket into specific implementation tasks. These are the ACTUAL tasks you will complete, not phases.

3. **Create progress.txt with goal task list:**
   ```
   # {TICKET_ID}: {Ticket Title}

   ## Goal Tasks
   - [ ] Task 1: {specific implementation task}
   - [ ] Task 2: {specific implementation task}
   - [ ] Task 3: {specific implementation task}
   - [ ] Visual validation with Playwright
   - [ ] Create PR

   ## Current: Task 1
   Started: {timestamp}
   ```

4. **Output the task list immediately:**
   ```
   ## {TICKET_ID} - Starting

   - [ ] Task 1: {description}
   - [ ] Task 2: {description}
   - [ ] Task 3: {description}
   - [ ] Visual validation
   - [ ] Create PR
   ```

### Phase 1: PRD Creation (Brief)

Create a brief PRD in progress.txt:

```
## PRD
**Problem:** {one sentence}
**Solution:** {one sentence}
**Acceptance Criteria:**
- {criterion 1}
- {criterion 2}
```

### Phase 2: Agent Selection

Select agent based on task type:

| Task Type | Agent |
|-----------|-------|
| UI/CSS only | frontend-developer |
| API/DB only | backend-developer |
| Both UI + API | fullstack-developer |

### Phase 3: Implementation Loop

For each task:

1. Mark task as current in output
2. Implement the change
3. Run feedback loops (lint, tests)
4. Commit with descriptive message
5. Mark task complete, move to next
6. Update progress.txt

**Output per iteration:**
```
## {TICKET_ID} - Iteration {N}/{max}

- [x] Find the CSS causing white block
- [ ] **→ Fix container height** (current)
- [ ] Test fix locally
- [ ] Visual validation with Playwright
- [ ] Create PR

Status: ✓ Lint | ✓ Tests | ○ Pending commit
```

### Phase 4: Visual Validation

**IMPORTANT:** For any UI changes, validate visually before creating PR.

#### Use agent-browser CLI (default for frontend):
```bash
# Open local dev server
agent-browser open http://localhost:3000

# Get accessibility tree to find elements
agent-browser snapshot

# Navigate to the page with changes
agent-browser click @nav-link  # or CSS selector

# Take screenshot for PR
agent-browser screenshot {TICKET_ID}-after.png

# Test mobile viewport
agent-browser close
agent-browser open http://localhost:3000 --viewport 375x812
agent-browser screenshot {TICKET_ID}-mobile.png

# Clean up
agent-browser close
```

#### Use Playwright MCP (for complex multi-step flows):

When bug requires reproducing a user flow (signup, checkout, forms with CAPTCHA):

```
1. mcp__plugin_playwright_playwright__browser_navigate - Open URL
2. mcp__plugin_playwright_playwright__browser_snapshot - Get element refs
3. mcp__plugin_playwright_playwright__browser_click - Click elements
4. mcp__plugin_playwright_playwright__browser_type - Fill inputs
5. mcp__plugin_playwright_playwright__browser_take_screenshot - Capture screenshots
6. mcp__plugin_playwright_playwright__browser_close - Close browser
```

**When to use which:**

| Scenario | Tool |
|----------|------|
| Simple page screenshot | agent-browser |
| CSS/layout validation | agent-browser |
| Responsive testing | agent-browser |
| Multi-step user flow | Playwright MCP |
| Forms with modals/iframes | Playwright MCP |
| Signup/checkout flows | Playwright MCP |

### Phase 5: PR Creation

When all tasks complete:

1. Final commit if needed
2. Use /beehiiv:create-pr skill
3. Output: `<promise>COMPLETE</promise>`

### Commit Guidelines

After EACH task (not at the end):

```bash
git add -A
git commit -m "$(cat <<'EOF'
{type}: {short description}

- {What changed}

Ticket: {TICKET_ID}
EOF
)"
```

### Progress File Format

Keep progress.txt updated:

```
# {TICKET_ID}: {Title}

## Goal Tasks
- [x] Task 1: Find CSS issue
- [x] Task 2: Fix container height
- [ ] Task 3: Visual validation
- [ ] Task 4: Create PR

## Current: Task 3
Status: Implementation complete, validating...

## Log
- Found issue in SurveyForm.tsx line 45
- Fixed by removing min-height: 100vh
- Committed: fix: remove extra whitespace in survey form
```

## Error Recovery

If stuck:
1. Check progress.txt for context
2. Check git log
3. Ask user for guidance

## Completion

Output `<promise>COMPLETE</promise>` ONLY when:
- All goal tasks marked [x]
- PR created successfully

## Example Full Output

```
## WEB-6135 - Starting

- [ ] Investigate CSS causing white block
- [ ] Fix the container/layout issue
- [ ] Visual validation with Playwright
- [ ] Create PR

---

## WEB-6135 - Iteration 1/10

- [x] Investigate CSS causing white block
- [ ] **→ Fix the container/layout issue** (current)
- [ ] Visual validation with Playwright
- [ ] Create PR

Status: ✓ Lint | ✓ Tests | ○ Pending

---

## WEB-6135 - Iteration 2/10

- [x] Investigate CSS causing white block
- [x] Fix the container/layout issue
- [ ] **→ Visual validation with Playwright** (current)
- [ ] Create PR

Status: ✓ Lint | ✓ Tests | ✓ Committed

---

## WEB-6135 - Iteration 3/10

- [x] Investigate CSS causing white block
- [x] Fix the container/layout issue
- [x] Visual validation with Playwright
- [ ] **→ Create PR** (current)

Status: ✓ Lint | ✓ Tests | ✓ Committed

---

## WEB-6135 - Complete

- [x] Investigate CSS causing white block
- [x] Fix the container/layout issue
- [x] Visual validation with Playwright
- [x] Create PR

PR: https://github.com/beehiiv/swarm/pull/XXXX

<promise>COMPLETE</promise>
```
