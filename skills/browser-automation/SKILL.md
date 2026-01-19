---
name: browser
description: |
  Browser automation using agent-browser CLI. Use for visual testing, E2E validation, web scraping, and interacting with web pages.

  <example>
  user: "/browser open https://localhost:3000 and take a screenshot"
  assistant: "Opening the page and capturing screenshot..."
  </example>

  <example>
  user: "check if the login form works on staging"
  assistant: "I'll use the browser skill to test the login flow..."
  </example>

  <example>
  user: "/browser snapshot"
  assistant: "Getting the accessibility tree of the current page..."
  </example>
---

# Browser Automation Skill

You have access to `agent-browser` CLI for browser automation. Use this for visual testing, E2E validation, and web scraping.

## Arguments

Parse the input for:
- `<url>` - URL to open (optional if browser already open)
- `--screenshot <path>` - Take screenshot after action
- `--headless` - Run in headless mode (default: headed for debugging)

## Quick Reference

### Core Commands

```bash
# Navigation
agent-browser open <url>              # Open URL
agent-browser back                    # Go back
agent-browser forward                 # Go forward
agent-browser reload                  # Reload page

# Get Page State (AI-FRIENDLY)
agent-browser snapshot                # Get accessibility tree with @refs
agent-browser screenshot [path]       # Take screenshot
agent-browser pdf <path>              # Save as PDF

# Interactions (use @ref from snapshot or CSS selectors)
agent-browser click <sel>             # Click element
agent-browser fill <sel> <text>       # Clear and fill input
agent-browser type <sel> <text>       # Type into element
agent-browser press <key>             # Press key (Enter, Tab, etc.)
agent-browser hover <sel>             # Hover over element
agent-browser select <sel> <value>    # Select dropdown option
agent-browser check <sel>             # Check checkbox
agent-browser uncheck <sel>           # Uncheck checkbox

# Get Info
agent-browser get text <sel>          # Get text content
agent-browser get html <sel>          # Get HTML
agent-browser get value <sel>         # Get input value
agent-browser get url                 # Get current URL
agent-browser get title               # Get page title

# Waiting
agent-browser wait <sel>              # Wait for element
agent-browser wait <ms>               # Wait milliseconds

# Cleanup
agent-browser close                   # Close browser
```

## Workflow Pattern

### 1. Visual Testing (Screenshot Comparison)

```bash
# Open local dev server
agent-browser open http://localhost:3000

# Navigate to page
agent-browser click @nav-dashboard    # or use CSS: "#nav-dashboard"

# Take screenshot for visual comparison
agent-browser screenshot screenshots/dashboard-$(date +%Y%m%d).png

# Close when done
agent-browser close
```

### 2. E2E Flow Testing

```bash
# Test login flow
agent-browser open http://localhost:3000/login

# Get snapshot to find form elements
agent-browser snapshot
# Output: @e1 textbox "Email", @e2 textbox "Password", @e3 button "Sign In"

# Fill form using refs
agent-browser fill @e1 "test@example.com"
agent-browser fill @e2 "password123"
agent-browser click @e3

# Wait for redirect
agent-browser wait 2000
agent-browser get url  # Should be /dashboard

# Verify dashboard loaded
agent-browser snapshot  # Check for expected elements
```

### 3. Web Scraping

```bash
# Open external site
agent-browser open https://example.com/pricing

# Get accessibility tree
agent-browser snapshot

# Extract specific data
agent-browser get text ".pricing-card"
agent-browser get html ".features-list"

# Screenshot for reference
agent-browser screenshot pricing-comparison.png

agent-browser close
```

## Integration with Ralph Workflow

When used during ralph-workflow, add visual validation:

```bash
# After implementing UI changes
agent-browser open http://localhost:3000

# Navigate to changed component
agent-browser click "[data-testid='new-feature']"

# Screenshot for PR
agent-browser screenshot pr-screenshots/feature-$(date +%Y%m%d).png

# Validate accessibility
agent-browser snapshot  # Check for proper ARIA labels

agent-browser close
```

## Element Selection

**Prefer accessibility refs from snapshot:**
```bash
agent-browser snapshot
# @e1 button "Submit"
# @e2 textbox "Email"

agent-browser click @e1
agent-browser fill @e2 "test@test.com"
```

**CSS selectors also work:**
```bash
agent-browser click "#submit-btn"
agent-browser fill "[name='email']" "test@test.com"
agent-browser click ".btn-primary"
```

**Data-testid (recommended for testing):**
```bash
agent-browser click "[data-testid='submit-button']"
```

## Session Management

agent-browser maintains a single browser session until closed:

```bash
agent-browser open https://site.com    # Starts session
agent-browser click @e1                 # Uses same session
agent-browser screenshot page.png       # Uses same session
agent-browser close                     # Ends session
```

For multiple sessions, use `--session`:
```bash
agent-browser open https://a.com --session a
agent-browser open https://b.com --session b
agent-browser click @e1 --session a
agent-browser close --session a
agent-browser close --session b
```

## Error Handling

If an element is not found:
1. Run `agent-browser snapshot` to see current page state
2. Check if page has loaded (`agent-browser wait <selector>`)
3. Verify selector is correct

If page doesn't load:
1. Check if dev server is running
2. Try `agent-browser get url` to see current URL
3. Check for redirects or auth requirements

## Common Patterns

### Wait for element then click
```bash
agent-browser wait "[data-loaded='true']"
agent-browser click @submit
```

### Fill form and submit
```bash
agent-browser fill @email "test@test.com"
agent-browser fill @password "secret"
agent-browser click @submit
agent-browser wait 1000
agent-browser get url  # Verify redirect
```

### Check responsive design
```bash
agent-browser open http://localhost:3000 --viewport 375x812  # Mobile
agent-browser screenshot mobile.png
agent-browser close

agent-browser open http://localhost:3000 --viewport 1920x1080  # Desktop
agent-browser screenshot desktop.png
agent-browser close
```

## Cleanup

Always close the browser when done:
```bash
agent-browser close
```

If browser gets stuck:
```bash
pkill -f chromium  # Force kill
```
