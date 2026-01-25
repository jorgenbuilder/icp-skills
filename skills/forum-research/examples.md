## Login (agent-browser)

```bash
# ALWAYS launch browser first
agent-browser launch

agent-browser open https://forum.dfinity.org/login
agent-browser snapshot -i
# Fill username/password using refs from snapshot
agent-browser fill @e1 "$DFINITY_FORUM_USERNAME"
agent-browser fill @e2 "$DFINITY_FORUM_PASSWORD"
agent-browser click @e3
agent-browser wait --url "**/latest"
agent-browser open "https://forum.dfinity.org/u/$DFINITY_FORUM_USERNAME.json"
```

## Read a topic via JSON

```bash
agent-browser open "https://forum.dfinity.org/t/some-topic/12345.json"
agent-browser get text "pre"
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
