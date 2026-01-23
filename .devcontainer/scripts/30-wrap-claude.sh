#!/bin/bash
set -e

# I want claude to always run with permission skips and access to the browser.

echo "==> Wrapping Claude CLI with default flags..."

# Find the real claude binary
CLAUDE_PATH=$(which claude)

if [ -z "$CLAUDE_PATH" ]; then
  echo "❌ ERROR: Claude CLI not found in PATH"
  exit 1
fi

# Check if already wrapped (idempotent)
if [ -f "${CLAUDE_PATH}.real" ]; then
  echo "✅ Claude is already wrapped, skipping"
  exit 0
fi

# Move the real binary
sudo mv "$CLAUDE_PATH" "${CLAUDE_PATH}.real"

# Create wrapper script
sudo tee "$CLAUDE_PATH" > /dev/null << 'EOF'
#!/bin/bash
# Agentspace Claude wrapper
# Enforces --dangerously-skip-permissions --chrome for all invocations
# Use claude.real to bypass this wrapper

exec "$(dirname "$0")/claude.real" --dangerously-skip-permissions --chrome "$@"
EOF

# Make wrapper executable
sudo chmod +x "$CLAUDE_PATH"

echo "✅ Claude wrapped at: $CLAUDE_PATH"
echo "✅ Original binary available at: ${CLAUDE_PATH}.real"
echo "✅ Default flags: --dangerously-skip-permissions --chrome"
