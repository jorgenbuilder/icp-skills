# Installing the `makespace` Command

The `makespace` command is a local CLI tool that creates new projects from the agentspace template.

## Prerequisites

Before installing, ensure you have:

1. **GitHub CLI** installed and authenticated
   ```bash
   gh --version
   gh auth login  # if not already authenticated
   ```

2. **jq** installed (JSON processor)
   ```bash
   # macOS
   brew install jq

   # Ubuntu/Debian
   sudo apt-get install jq

   # Other: See https://stedolan.github.io/jq/download/
   ```

3. **User Codespaces secrets** created in GitHub:
   - Go to: https://github.com/settings/codespaces
   - Create secrets:
     - `ANTHROPIC_API_KEY` - Your Anthropic API key
     - `GH_PAT` - GitHub Personal Access Token with `repo` and `codespace` scopes

## Installation Options

### Option 1: Install to `~/.local/bin` (Recommended)

This method installs `makespace` as a standalone script on your PATH.

```bash
# Create directory if it doesn't exist
mkdir -p ~/.local/bin

# Copy the script
cp makespace ~/.local/bin/makespace

# Make it executable (if not already)
chmod +x ~/.local/bin/makespace

# Ensure ~/.local/bin is on your PATH
# Add this to your ~/.zshrc or ~/.bashrc if not already present:
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc

# Reload your shell configuration
source ~/.zshrc  # or source ~/.bashrc
```

Verify installation:
```bash
makespace --help
```

### Option 2: Install to `/usr/local/bin`

This method requires sudo but makes the command available system-wide.

```bash
# Copy the script (requires sudo)
sudo cp makespace /usr/local/bin/makespace

# Make it executable
sudo chmod +x /usr/local/bin/makespace
```

Verify installation:
```bash
makespace --help
```

### Option 3: Shell Function (Quick Setup)

Add this function to your `~/.zshrc` or `~/.bashrc`:

```bash
makespace() {
  /path/to/agentspace-template/agentspace/local-install/makespace "$@"
}
```

Replace `/path/to/agentspace-template` with the actual path to this repository.

Then reload your shell:
```bash
source ~/.zshrc  # or source ~/.bashrc
```

### Option 4: Shell Alias (Simplest)

Add this line to your `~/.zshrc` or `~/.bashrc`:

```bash
alias makespace='/path/to/agentspace-template/agentspace/local-install/makespace'
```

Replace `/path/to/agentspace-template` with the actual path to this repository.

Then reload your shell:
```bash
source ~/.zshrc  # or source ~/.bashrc
```

## Configuration

The `makespace` script has sensible defaults, but you can customize them:

### Default Owner

By default, repositories are created under `jorgenbuilder`. To change this:

1. Edit the script:
   ```bash
   # Open the script in your editor
   code ~/.local/bin/makespace  # or vi, nano, etc.
   ```

2. Change the `DEFAULT_OWNER` variable:
   ```bash
   DEFAULT_OWNER="your-github-username"
   ```

3. Save and exit

Alternatively, always use the `--owner` flag:
```bash
makespace my-project --owner your-github-username
```

### Default Template

By default, `makespace` uses `jorgenbuilder/agentspace-template`. To change:

1. Edit the script and change `DEFAULT_TEMPLATE`:
   ```bash
   DEFAULT_TEMPLATE="your-org/your-template"
   ```

2. Or use the `--template` flag:
   ```bash
   makespace my-project --template your-org/your-template
   ```

## Usage

### Basic usage (private repo, default owner)
```bash
makespace my-project
```

### Create a public repository
```bash
makespace my-project --public
```

### Specify owner
```bash
makespace my-project --owner myorg
```

### Use a different template
```bash
makespace my-project --template myorg/custom-template
```

### Combined options
```bash
makespace my-project --owner myorg --public --template myorg/custom-template
```

## What `makespace` Does

When you run `makespace my-project`, it:

1. Creates a new GitHub repository from the template
2. Clones the repository to your local machine
3. Grants the repository access to your Codespaces secrets:
   - `ANTHROPIC_API_KEY`
   - `GH_PAT`
4. Creates a GitHub Codespace for the repository
5. Opens the Codespace in your browser

The Codespace will automatically bootstrap with Claude Code, Beads, and all configured tools (3-5 minutes).

## Troubleshooting

### Command not found

If you get "command not found" after installation:

1. **Check PATH** (for Option 1):
   ```bash
   echo $PATH | grep -o "$HOME/.local/bin"
   ```
   If empty, add to your shell config:
   ```bash
   echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
   source ~/.zshrc
   ```

2. **Check file exists**:
   ```bash
   ls -l ~/.local/bin/makespace
   ```

3. **Check executable bit**:
   ```bash
   chmod +x ~/.local/bin/makespace
   ```

### GitHub CLI not authenticated

```bash
gh auth status

# If not authenticated:
gh auth login
```

### jq not installed

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq
```

### Repository creation fails

1. Check repository doesn't already exist: https://github.com/owner/repo-name
2. Verify you have permission to create repos under the specified owner
3. Check GitHub CLI has necessary scopes: `gh auth refresh -h github.com -s repo,codespace`

### Secret attachment fails

1. Verify secrets exist: https://github.com/settings/codespaces
2. Ensure secret names match exactly: `ANTHROPIC_API_KEY`, `GH_PAT`
3. Check GitHub CLI authentication: `gh auth status`

## Uninstallation

### Remove from `~/.local/bin`
```bash
rm ~/.local/bin/makespace
```

### Remove from `/usr/local/bin`
```bash
sudo rm /usr/local/bin/makespace
```

### Remove shell function/alias
Edit your `~/.zshrc` or `~/.bashrc` and remove the `makespace` function or alias, then:
```bash
source ~/.zshrc  # or source ~/.bashrc
```

## Next Steps

After installing `makespace`:

1. Create your first project:
   ```bash
   makespace my-first-project
   ```

2. Wait for Codespace to bootstrap (3-5 minutes)

3. Verify your environment using the checklist in `VERIFY.md`

4. Start building with Claude Code and Beads!
