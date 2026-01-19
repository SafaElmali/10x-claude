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

## Workflow Phases

### Phase 0: Setup & Context Gathering

1. **Fetch ticket details:**
   ```
   Use mcp__plugin_linear_linear__get_issue to fetch ticket details
   ```

2. **Analyze ticket scope:**
   - Small task (bug fix, minor change): 5-10 iterations
   - Medium task (new feature component): 15-25 iterations
   - Large task (major feature): 30-50 iterations

3. **Create/Update progress.txt:**
   ```
   ## Ralph Workflow Progress

   Ticket: {TICKET_ID}
   Started: {timestamp}
   Iteration: 1

   ### Tasks
   - [ ] Phase 1: PRD Creation
   - [ ] Phase 2: Agent Selection
   - [ ] Phase 3: Implementation
   - [ ] Phase 4: Testing & Validation
   - [ ] Phase 5: PR Creation

   ### Progress Log
   ```

4. **Ask clarifying questions if needed:**
   - If requirements are ambiguous, ASK before proceeding
   - If technical approach is unclear, ASK
   - If acceptance criteria missing, ASK

### Phase 1: PRD Creation (use project-manager agent)

Use the `project-manager` agent to create a PRD:

```markdown
## PRD: {Ticket Title}

### Problem Statement
{What problem are we solving?}

### Requirements
1. {Functional requirement 1}
2. {Functional requirement 2}
...

### Acceptance Criteria
- [ ] {Criterion 1}
- [ ] {Criterion 2}
...

### Technical Approach
{High-level technical approach}

### Out of Scope
{What we're NOT doing}
```

Update progress.txt after PRD is complete.

### Phase 2: Agent Selection

Analyze the ticket to determine the best agent:

**Use `frontend-developer` agent when:**
- UI component changes ONLY
- React/Next.js work without API changes
- Styling, CSS, Tailwind
- Client-side state management
- Accessibility improvements
- Responsive design

**Use `backend-developer` agent when:**
- API endpoints ONLY
- Database changes/migrations without UI
- Server-side logic
- Authentication/authorization logic
- Background jobs
- External service integrations

**Use `fullstack-developer` agent when:**
- Feature requires BOTH API and UI changes
- New feature with database → API → UI flow
- Data consistency issues between frontend and backend
- Real-time features (WebSocket/SSE + UI subscriptions)
- Adding new data models that need API endpoints AND UI components
- Bug fixes that span multiple layers

**Agent Selection Decision Tree:**
```
Does the task require UI changes?
├── NO → backend-developer
└── YES → Does the task require API/database changes?
          ├── NO → frontend-developer
          └── YES → fullstack-developer
```

**Examples:**
| Task | Agent | Reason |
|------|-------|--------|
| "Add border radius to button" | frontend-developer | UI only |
| "Create endpoint for user stats" | backend-developer | API only |
| "Add user profile page with API" | fullstack-developer | API + UI |
| "Fix checkout total mismatch" | fullstack-developer | Spans layers |
| "Add dark mode toggle" | frontend-developer | Client-side only |
| "Add webhook for payments" | backend-developer | Server-side only |
| "Add favorites feature" | fullstack-developer | DB + API + UI |

Log agent selection reasoning in progress.txt.

### Phase 3: Implementation Loop

For each implementation task, follow this loop:

```
REPEAT until all acceptance criteria met OR max iterations reached:

1. Show current task list as checkboxes:
   - [ ] Task 1 description
   - [x] Task 2 (completed)
   - [ ] Task 3 description

2. Work on next unchecked task

3. After completing task:
   a. Run feedback loops (see below)
   b. If frontend changes: run biome
   c. If tests fail: fix and retry
   d. Commit the change with descriptive message
   e. Update progress.txt
   f. Check task as complete

4. If blocked or uncertain:
   - ASK the user for clarification
   - Document the question and answer in progress.txt

5. If you discover something important:
   - Note it for CLAUDE.md update
   - Continue implementation
```

### Feedback Loops (run after EVERY change)

**For frontend changes (swarm project):**
```bash
# Lint check (includes formatting and import organization)
pnpm lint

# If node_modules not installed, skip local linting - CI will catch issues
# The CI runs: biome check ./src --linter-enabled=true --formatter-enabled=false
```

**For all changes:**
```bash
# Run tests relevant to changed files
pnpm test  # or bundle exec rspec for Ruby
```

**If linting fails:**
1. Fix the issue immediately (usually import organization)
2. Re-run linting
3. Only proceed when all checks pass

**Note:** If `pnpm lint` fails due to missing node_modules, verify code follows existing patterns and commit - CI will validate.

### Phase 4: Testing & Validation

Before marking implementation complete:

1. **Run full test suite**
2. **Verify all acceptance criteria are met**
3. **Check for any console errors/warnings**
4. **Review changes for security issues**
5. **Visual validation (for frontend changes)** - see below

If tests fail:
- Do NOT proceed to PR
- Fix failing tests
- Re-run validation
- Continue loop until ALL tests pass

#### Visual Validation (Frontend Changes Only)

When the task involves UI changes, use `agent-browser` to validate visually:

```bash
# 1. Ensure dev server is running (in another terminal)
# pnpm dev  # or whatever starts the local server

# 2. Open the page with changes
agent-browser open http://localhost:3000

# 3. Navigate to the changed component/page
agent-browser snapshot  # Get element refs
agent-browser click @nav-link  # or use CSS selector

# 4. Take screenshot for PR
agent-browser screenshot pr-screenshots/{TICKET_ID}-$(date +%Y%m%d).png

# 5. Validate accessibility
agent-browser snapshot  # Check for proper ARIA labels, roles

# 6. Test responsive (optional)
agent-browser close
agent-browser open http://localhost:3000 --viewport 375x812
agent-browser screenshot pr-screenshots/{TICKET_ID}-mobile.png

# 7. Clean up
agent-browser close
```

**When to use visual validation:**
- New UI components
- Layout changes
- Styling updates
- Responsive design changes
- Accessibility improvements

**Skip visual validation when:**
- Backend-only changes
- No dev server available
- Pure refactoring without visual changes

### Phase 5: PR Creation

When all tests pass and acceptance criteria are met:

1. **Final commit** (if any uncommitted changes)

2. **Use /beehiiv:create-pr skill** to create the PR

3. **Output completion promise:**
   ```
   <promise>COMPLETE</promise>
   ```

### Commit Guidelines

After EACH completed task (not at the end):

```bash
git add -A
git commit -m "$(cat <<'EOF'
{type}: {short description}

- {What changed}
- {Why it changed}

Ticket: {TICKET_ID}
```

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `style`, `chore`

### Progress File Format

Update `progress.txt` after each significant action:

```
## Iteration {N}

### Completed
- {Task description} - {files changed}
- Decision: {key decision and reasoning}

### Next
- {Next task to tackle}

### Blockers
- {Any blockers or questions}
```

### Learning Updates

If you discover:
- A useful pattern → note for CLAUDE.md
- A common pitfall → note for CLAUDE.md
- A missing skill → note for skill creation
- A project convention → note for CLAUDE.md

At end of workflow, summarize learnings for user to review and add to CLAUDE.md.

### Common Patterns (swarm/beehiiv)

**Dream Components - Mobile responsive attributes:**
When adding mobile-specific settings to dream-components:
1. Add `mobile{Property}` to type definition (e.g., `mobileWidth`, `mobilePadding`)
2. Use CSS variables in styles: `var(--mobile-width, var(--width))`
3. Pass CSS variables in component: `'--mobile-width': mobileWidth`
4. Update BOTH the component AND the view file (e.g., `SignupModalView.tsx`)
5. Use `AddableSettings` + `SimpleLengthSettings` for optional mobile overrides in settings panel

**Dream Components - CSS variables for responsive styles:**
Always use CSS variables, NOT inline styles for responsive properties. Inline styles override CSS media queries.
```tsx
// ✓ Correct
style={{ '--border-radius': borderRadius }}

// ✗ Wrong - breaks mobile override
style={{ borderRadius: borderRadius }}
```

### Output Format Per Iteration

Each iteration should output:

```
## Iteration {N}/{max}

### Task List
- [x] Completed task 1
- [x] Completed task 2
- [ ] **Current:** {current task}
- [ ] Pending task 4

### Current Action
{What you're doing now}

### Status
{pass/fail} Tests | {pass/fail} Biome | {committed/pending} Git

### Notes
{Any questions, blockers, or discoveries}
```

## Error Recovery

**If implementation is stuck:**
1. Review progress.txt for context
2. Check git log for what's been done
3. Ask user for guidance
4. Document the resolution

**If tests keep failing:**
1. Isolate the failing test
2. Debug step by step
3. If it's a flaky test, note it
4. If it's a real bug, fix it
5. Never skip tests without user approval

## Completion

Output `<promise>COMPLETE</promise>` ONLY when:
- All acceptance criteria are met
- All tests pass
- PR is created successfully
- progress.txt is up to date

## Cleanup

After workflow completion, remind user:
- Delete progress.txt (session-specific)
- Run `work-tickets --cleanup` if worktrees were used
- Review suggested CLAUDE.md updates
