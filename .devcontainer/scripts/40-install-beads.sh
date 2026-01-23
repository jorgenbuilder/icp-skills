#!/bin/bash
set -e

echo "==> Installing Beads CLI..."

curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash
claude plugin marketplace add steveyegge/beads
claude plugin install beads
bd init --quiet
bd setup claude