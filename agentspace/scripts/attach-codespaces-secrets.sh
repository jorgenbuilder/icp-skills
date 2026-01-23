#!/bin/bash
set -e

# Attach Codespaces Secrets to Repository
# Usage: ./attach-codespaces-secrets.sh <owner/repo>

if [ $# -ne 1 ]; then
  echo "Usage: $0 <owner/repo>"
  echo "Example: $0 jorgenbuilder/my-project"
  exit 1
fi

REPO_SLUG="$1"

echo "==> Attaching Codespaces secrets to repository: $REPO_SLUG"
echo ""

# Verify GitHub CLI is authenticated
if ! gh auth status >/dev/null 2>&1; then
  echo "❌ ERROR: GitHub CLI is not authenticated"
  echo "Run: gh auth login"
  exit 1
fi

# Get repository ID
echo "Fetching repository ID..."
REPO_ID=$(gh api "repos/$REPO_SLUG" --jq .id 2>/dev/null)

if [ -z "$REPO_ID" ]; then
  echo "❌ ERROR: Could not fetch repository ID for $REPO_SLUG"
  echo "Ensure the repository exists and you have access to it"
  exit 1
fi

echo "Repository ID: $REPO_ID"
echo ""

# List of secrets to attach
SECRETS=(
  "ANTHROPIC_API_KEY"
  "GH_PAT"
  "VERCEL_TOKEN"
)

# Attach each secret to the repository
SUCCESS_COUNT=0
FAILED_COUNT=0

for SECRET in "${SECRETS[@]}"; do
  echo "Attaching secret: $SECRET"

  if gh api -X PUT "/user/codespaces/secrets/$SECRET/repositories/$REPO_ID" >/dev/null 2>&1; then
    echo "  ✅ Successfully attached: $SECRET"
    ((SUCCESS_COUNT++))
  else
    echo "  ❌ Failed to attach: $SECRET"
    echo "     Ensure the secret exists in your user Codespaces secrets"
    ((FAILED_COUNT++))
  fi
done

echo ""
echo "==> Summary:"
echo "  Successfully attached: $SUCCESS_COUNT"
echo "  Failed: $FAILED_COUNT"

if [ $FAILED_COUNT -gt 0 ]; then
  echo ""
  echo "❌ Some secrets failed to attach"
  echo "Create missing secrets at: https://github.com/settings/codespaces"
  exit 1
fi

echo ""
echo "✅ All secrets attached successfully to $REPO_SLUG"
echo "You can now create a Codespace for this repository"
