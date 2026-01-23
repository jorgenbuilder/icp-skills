# Internet Computer Agent Skills

Skills are folders of instructions and resources that an agent loads to perform
specialized tasks. This repository collects Agent Skills focused on building,
operating, and shipping on the Internet Computer (ICP).

## About this repository

This repo is intentionally structured like `anthropics/skills` but scoped to
ICP workflows. Each skill is self-contained with its own `SKILL.md`, and the
`skills/` directory is the canonical home for all ICP-related skills.

## Skill sets

All skills live under `skills/`. Current skills include:

- `skills/icp-cli/` — Use the `icp` CLI for local networks, builds, deploys,
  canister operations, identities, and cycles/tokens.

## Repository structure

Each skill is a folder with a `SKILL.md` and optional references:

```
skills/
  icp-cli/
    SKILL.md
```

## Using these skills

These skills are plain, portable skill folders and should work with all agents,
including:

- Claude Code
- Claude.ai
- Anthropic API agents
- Cursor
- OpenAI Codex
- Gemini CLI
- OpenCode
- antigravity

Install them in your agent's skill directory and keep the folder name the same
as the skill identifier to make discovery clear. For installation instructions,
see https://skills.sh/.

## Creating new skills

To add new ICP skills, follow the same structure as the existing ones:

1. Create `skills/<skill-name>/SKILL.md`
2. Use concise instructions, examples, and references
3. Keep terminology consistent across skills

## Contributing

Please improve existing skills when you spot gaps, missing workflows, or
outdated guidance, and open PRs to add new skills or expand coverage. Note:
these skills were largely created by pointing Claude at docs with the
Anthropics `create-skill` skill
([skill-creator](https://skills.sh/anthropics/skills/skill-creator)).

## References

- https://github.com/anthropics/skills
