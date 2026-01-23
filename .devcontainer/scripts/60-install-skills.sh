#!/bin/bash
set -e

echo "==> Installing skills..."

npm i skills
npx skills add vercel-labs/agent-skills -s "vercel-react-best-practices" -a claude-code -g -y
npx skills add vercel-labs/agent-skills -s "web-design-guidelines" -a claude-code -g -y
npx skills add vercel-labs/agent-browser -s "agent-browser" -a claude-code -g -y
