---
name: forum-research
description: Research and read content on forum.dfinity.org (Discourse). Use when the user asks to browse, search, summarize, or analyze Dfinity forum topics or users. Read-only access with authenticated browsing and JSON endpoints.
---

# Forum Research (Dfinity)

## Scope

This skill supports read-only research on `forum.dfinity.org` using authenticated browsing and Discourse JSON endpoints.

## Required dependency

This skill depends on the `agent-browser` skill from vercel-labs. Install it first:

```
npx skills add https://github.com/vercel-labs/agent-browser --skill agent-browser
```

## Guardrails (strict)

- Read-only only. Never post, reply, like, bookmark, or edit.
- Use GET requests for all research and reading.
- Exception: authentication may require a POST to the login endpoint. No other non-GET requests are allowed.
- If a user asks to post or modify content, refuse and explain the read-only policy.

## Browser initialization (CRITICAL)

**ALWAYS call `agent-browser launch` first before ANY other agent-browser commands.**

If you get the error "Browser not launched. Call launch first", simply call `agent-browser launch` and then retry your command. This is a normal part of the workflow.

## Error handling and persistence

When using this skill, you may encounter errors. **Always persist through errors by:**

1. **Launch errors**: If you see "Browser not launched", call `agent-browser launch` and retry.
2. **Login errors**: If credentials fail, try again or check the credential source.
3. **Navigation errors**: If a page fails to load, retry the navigation.
4. **Element not found**: If snapshot elements change, take a fresh snapshot and update element refs.

**Do not give up after a single error.** Most errors can be resolved by:
- Launching the browser if not already launched
- Retrying the failed command
- Taking a fresh snapshot to update element references
- Verifying you're on the expected page before interacting with it

## Stage 1: login only

1. Launch the browser with `agent-browser launch` (required first step).
2. Obtain credentials using one of the approved methods in `reference.md`.
3. Navigate to `https://forum.dfinity.org/login`.
4. Always choose the username/password option on the login page (ignore GitHub and passkey options).
5. Fill username and password, then submit.
6. Confirm login by opening `https://forum.dfinity.org/u/<username>.json`.

## Discourse JSON access

Discourse supports a JSON view for most pages by appending `.json` to the URL. Prefer JSON for structured reading:

- Topic: `https://forum.dfinity.org/t/<slug>/<id>.json`
- User: `https://forum.dfinity.org/u/<username>.json`
- Latest: `https://forum.dfinity.org/latest.json`

## Additional resources

- Credential sourcing, prompts, and constraints: `reference.md`
- Login examples: `examples.md`
- Forum category structure and navigation guide: `categories.md`
