## Login (agent-browser) - MANDATORY FIRST STEP

```bash
# ALWAYS launch browser first
agent-browser launch

# Login immediately before any research
agent-browser open https://forum.dfinity.org/login
agent-browser snapshot -i
# Fill username/password using refs from snapshot
agent-browser fill @e1 "$DFINITY_FORUM_USERNAME"
agent-browser fill @e2 "$DFINITY_FORUM_PASSWORD"
agent-browser click @e3
agent-browser wait --url "**/latest"

# CRITICAL: Verify login succeeded by checking top right of page
agent-browser snapshot -i
# Look at top right corner in the snapshot:
# - Account dropdown = logged in successfully
# - "Sign Up" and "Log In" buttons = login failed, try again

# Alternative: Check user profile JSON
agent-browser open "https://forum.dfinity.org/u/$DFINITY_FORUM_USERNAME.json"
# You should see your user profile data. If not, login failed - try again.
```

## Read a topic via JSON

```bash
agent-browser open "https://forum.dfinity.org/t/some-topic/12345.json"
agent-browser get text "pre"
```

## Verify login status (periodic check)

```bash
# During long research sessions, periodically check you're still logged in
agent-browser snapshot -i

# Check top right corner of the current page:
# - Account dropdown visible -> still logged in, continue
# - "Sign Up" and "Log In" buttons -> session expired, re-login immediately
```

## Complete workflow example

```bash
# 1. Launch browser
agent-browser launch

# 2. LOGIN FIRST (mandatory)
agent-browser open https://forum.dfinity.org/login
agent-browser snapshot -i
agent-browser fill @e1 "$DFINITY_FORUM_USERNAME"
agent-browser fill @e2 "$DFINITY_FORUM_PASSWORD"
agent-browser click @e3
agent-browser wait --url "**/latest"

# 3. Verify login - check top right of page
agent-browser snapshot -i
# Look for account dropdown in top right = logged in successfully

# 4. NOW you can do research
agent-browser open "https://forum.dfinity.org/latest.json"
agent-browser open "https://forum.dfinity.org/search?q=security"

# 5. After many operations, verify still logged in
agent-browser snapshot -i
# Check top right: account dropdown = still logged in
```

## Error recovery example

If you get "Browser not launched" error:

```bash
# This will fail if browser not launched
agent-browser open "https://forum.dfinity.org/search?q=security"
# Error: Browser not launched. Call launch first.

# FIX: Launch browser first
agent-browser launch

# Now retry the original command
agent-browser open "https://forum.dfinity.org/search?q=security"
# Success!
```
