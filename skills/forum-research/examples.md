## Login (agent-browser)

```bash
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
