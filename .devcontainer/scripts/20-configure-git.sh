#!/bin/bash
set -e

echo "==> Configuring git for cross-repo access..."

# Configure git to use GH_PAT for all GitHub operations
# This lets me access all my repos from one codespace
git config --global url."https://${GH_PAT}@github.com/".insteadOf "https://github.com/"

# Configure GitHub CLI to authenticate (if not already done)
if ! gh auth status >/dev/null 2>&1; then
  echo "$GH_PAT" | gh auth login --with-token
fi

# Set default git identity (using GitHub CLI to get authenticated user)
GH_USER=$(gh api user --jq .login 2>/dev/null || echo "vscode")
GH_EMAIL=$(gh api user --jq .email 2>/dev/null || echo "vscode@codespace")

git config --global user.name "$GH_USER"
git config --global user.email "$GH_EMAIL"

echo "✅ Git configured for user: $GH_USER <$GH_EMAIL>"
echo "✅ Cross-repo operations will use authenticated PAT"
