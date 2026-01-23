# Agentspace Template

A GitHub Codespaces template for AI-powered development with Claude Code, Beads, and essential tooling pre-configured.

## What's Included

This template provides a fully bootstrapped development environment with:

- **Claude Code CLI** - Pre-installed with `--dangerously-skip-permissions --chrome` as default flags
- **Beads** - Git-backed issue tracker for multi-session work
- **GitHub CLI** - Authenticated with your PAT for cross-repo operations
- **Development tools** - tmux, fzf, ripgrep, jq, Node.js 20, Python 3, Chromium
- **Auto-configured Git** - Uses your GitHub PAT for seamless cross-repo cloning/pushing

## Prerequisites

Before using this template, ensure you have created **user Codespaces secrets**:

1. Go to GitHub Settings > Codespaces > Secrets
2. Create these secrets:
   - `ANTHROPIC_API_KEY` - Your Anthropic API key for Claude
   - `GH_PAT` - GitHub Personal Access Token with `repo` and `codespace` scopes

## Quick Start

### Option 1: Using the `makespace` command (recommended)

Install the `makespace` command locally (see installation instructions below), then:

```bash
makespace my-project-name
```

This will:
1. Create a new repository from this template
2. Clone it locally
3. Grant repository access to your Codespaces secrets
4. Create and open a Codespace

### Option 2: Manual setup

1. **Create repository from template**
   - Click "Use this template" on GitHub
   - Choose repository name and visibility
   - Create repository

2. **Grant secret access**
   ```bash
   git clone https://github.com/<owner>/<repo>.git
   cd <repo>
   ./agentspace/scripts/attach-codespaces-secrets.sh <owner>/<repo>
   ```

3. **Create Codespace**
   - Go to your repository on GitHub
   - Click "Code" > "Codespaces" > "Create codespace on main"
   - Wait for environment to bootstrap (3-5 minutes)

## How It Works

### Bootstrap Process

When a Codespace is created, the following scripts run automatically in order:

1. `00-validate-secrets.sh` - Verifies required secrets are available
2. `20-configure-git.sh` - Configures git with your PAT and GitHub identity
3. `30-wrap-claude.sh` - Wraps Claude CLI with default flags
4. `40-install-beads.sh` - Installs Beads CLI and configuration
5. `50-install-claude-skills.sh` - Installs Claude skills including Beads plugin

Note: Claude CLI automatically authenticates using the `ANTHROPIC_API_KEY` environment variable from your Codespaces secrets - no login command is required.

### Claude CLI Wrapper

The `claude` command is automatically wrapped to include:
- `--dangerously-skip-permissions` - Skip permission prompts for agent workflows
- `--chrome` - Enable Chrome/Chromium integration

To bypass the wrapper and use Claude with custom flags:
```bash
claude.real [your-flags]
```

### Git Configuration

Git is pre-configured to use your `GH_PAT` for all GitHub operations:
- Cross-repo cloning works without authentication prompts
- Pushing to other repositories works seamlessly
- Your GitHub username and email are automatically set

## Customization

### Adding Claude Skills

Edit `.devcontainer/scripts/50-install-claude-skills.sh`:

```bash
CLAUDE_SKILLS=(
  "beads"
  "your-skill@version"
  # Add more skills here
)
```

### Changing Default Claude Flags

Edit `.devcontainer/scripts/30-wrap-claude.sh` to modify the wrapper's default flags.

### Adding More Secrets

1. Create the user Codespaces secret in GitHub Settings
2. Add the secret name to `agentspace/scripts/attach-codespaces-secrets.sh`
3. Update `.devcontainer/devcontainer.json` to include the secret in `containerEnv`
4. Add validation in `.devcontainer/scripts/00-validate-secrets.sh`

## Verification

See [VERIFY.md](./VERIFY.md) for a complete verification checklist to ensure your Codespace is working correctly.

## Troubleshooting

### Secrets not available

If you see "Missing required secrets" error:
1. Verify secrets exist in GitHub Settings > Codespaces > Secrets
2. Run `./scripts/attach-codespaces-secrets.sh <owner>/<repo>`
3. Rebuild the Codespace or create a new one

### Claude CLI not working

1. Check Claude is installed: `which claude`
2. Verify API key is set: `echo "$ANTHROPIC_API_KEY" | wc -c` (should be > 1)
3. Test with real binary: `claude.real --version`
4. Check wrapper: `cat $(which claude)`

### Git authentication failing

1. Verify PAT is set: `echo "$GH_PAT" | wc -c` (should be > 1)
2. Check git config: `git config --global --get url.https://github.com/.insteadof`
3. Test GitHub CLI: `gh auth status`

## Repository Structure

```
.
├── .devcontainer/                      # GitHub Codespaces configuration
│   ├── Dockerfile                      # Base image with tools
│   ├── devcontainer.json              # Codespaces configuration
│   └── scripts/
│       ├── 00-validate-secrets.sh     # Secret validation
│       ├── 20-configure-git.sh        # Git configuration
│       ├── 30-wrap-claude.sh          # Claude CLI wrapper
│       ├── 40-install-beads.sh        # Beads installation
│       └── 50-install-claude-skills.sh # Claude skills installation
├── agentspace/                         # Template files (can be removed after setup)
│   ├── scripts/
│   │   └── attach-codespaces-secrets.sh # Secret attachment utility
│   ├── local-install/
│   │   ├── makespace                  # CLI tool for creating new repositories
│   │   └── INSTALL.md                 # Installation instructions
│   ├── README.md                       # Full template documentation
│   ├── QUICKSTART.md                   # Quick start guide
│   ├── SUMMARY.md                      # Template summary
│   ├── VERIFY.md                       # Verification checklist
│   └── DEPLOYMENT.md                   # Deployment guide
└── README.md                           # Project README (replace with your content)
```

## License

This template is provided as-is for use in your projects.
