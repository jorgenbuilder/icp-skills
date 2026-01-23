# ICP CLI Usage Skill

This repo provides a Cursor Agent Skill that guides users through common `icp` CLI workflows for local development, deploys, canister operations, identities, and cycles/tokens. Use it whenever a user asks for ICP CLI commands or needs help with an `icp` workflow.

## What the skill covers

- Quick start flow: `icp new`, local network, build, deploy, and call
- Local network commands: start, status, ping, stop
- Canister operations: create, install, call, status, settings
- Identity and principal management
- Cycles and token balance/transfer tasks
- Environment and network flags, with common pitfalls

## Location

The skill lives at:

- `skills/icp-cli-usage/SKILL.md`

## Usage guidance (high level)

- Default to local network workflows unless a target is specified.
- Use `-e/--environment` or `-n/--network` when a target is named, but never both.
- Suggest `--identity` when multiple identities might exist.
- Provide a minimal command set plus a short verify step.
- If call arguments are unknown, omit args to trigger the interactive prompt.

## Example workflow

```
icp new hello-icp
cd hello-icp
icp network start -d
icp deploy
icp canister call backend greet '("World")'
```

## References

- https://dfinity.github.io/icp-cli/
- https://dfinity.github.io/icp-cli/reference/cli/
- https://dfinity.github.io/icp-cli/guides/local-development/
- https://dfinity.github.io/icp-cli/guides/installation/
