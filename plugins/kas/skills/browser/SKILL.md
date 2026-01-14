# Browser Automation Skill

This skill handles browser automation tasks using **subagent architecture** to keep the main context window clean.

## Core Principle

**NEVER call Claude-in-Chrome MCP tools directly in main context.**

All browser automation is delegated to the `browser-automation` Task subagent which returns concise summaries.

## Detection Triggers

Activate this skill when detecting:

### Web Testing
- "test the website", "check the page", "verify the UI"
- "screenshot", "capture the screen", "take a picture"
- "does the site work", "is the page loading"

### Form Automation
- "fill out the form", "submit this form", "enter data"
- "sign up", "register", "create account" (with explicit user permission)
- "login", "authenticate" (without entering passwords directly)

### Data Extraction
- "scrape this page", "extract data from", "get the text"
- "what's on the page", "read the content", "parse the data"
- "find the price", "get the title", "extract the links"

### Workflow Automation
- "automate this workflow", "record these steps", "create a GIF"
- "click through", "navigate to", "go to page"
- "test the flow", "verify the process"

### Debugging & Monitoring
- "check console logs", "monitor network requests", "debug the page"
- "why is this failing", "what's the error", "inspect the page"

## Subagent Delegation Pattern

When a browser automation task is detected:

```
Task("Browser: {brief_description}

**Task:** {user_request}
**URL:** {target_url if provided}
**Actions:** {list of expected actions}

Using Claude-in-Chrome MCP tools:
1. Start with tabs_context_mcp to get current tab state
2. Create new tab or use existing based on context
3. Navigate, interact, extract data as needed
4. Capture screenshots/GIFs for multi-step workflows
5. Monitor console/network if debugging

Return ONLY a concise summary:
- Actions taken (e.g., "Navigated to X, filled form, clicked submit")
- Key findings (e.g., "Form submitted successfully", "Error: XYZ")
- Screenshots/visual evidence if captured
- Any errors or unexpected behavior

Do NOT include:
- Raw HTML or page source
- Verbose console logs (use pattern filtering)
- Detailed network request payloads
- Implementation details

subagent_type: browser-automation
")
```

## Examples

### Example 1: Test a Website

**User:** "Test if the login page at example.com works"

**Delegation:**
```
Task("Browser: Test login page functionality

**Task:** Verify login page at example.com loads and form is interactive
**URL:** https://example.com/login
**Actions:**
- Navigate to URL
- Screenshot the page
- Verify form elements exist (username, password, submit)
- Check console for errors

subagent_type: browser-automation
")
```

### Example 2: Extract Data

**User:** "Get all product prices from shop.example.com/products"

**Delegation:**
```
Task("Browser: Extract product prices

**Task:** Scrape product prices from shop.example.com/products
**URL:** https://shop.example.com/products
**Actions:**
- Navigate to products page
- Find all price elements
- Extract text content
- Return structured list

subagent_type: browser-automation
")
```

### Example 3: Workflow Automation

**User:** "Record a GIF of searching for 'laptops' on the site"

**Delegation:**
```
Task("Browser: Record search workflow

**Task:** Create GIF recording of search process
**URL:** {provided or current}
**Actions:**
- Start GIF recording
- Navigate to search
- Enter 'laptops' in search box
- Submit search
- Wait for results
- Stop recording and export GIF

subagent_type: browser-automation
")
```

## Security Reminders

The browser-automation agent is configured to:
- Never enter sensitive financial data
- Never enter passwords directly
- Request permission for purchases/downloads
- Avoid triggering browser dialogs

## Response Format

After subagent returns, summarize for user:

```
{Brief action summary}

{Key findings or results}

{Screenshot/GIF if captured}

{Next steps or recommendations if applicable}
```

Keep it concise and actionable.
