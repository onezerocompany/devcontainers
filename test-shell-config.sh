#!/bin/bash
# Test script to verify shell configuration in devcontainer

set -e

echo "=== Testing Shell Configuration ==="
echo ""

# Test with local build
IMAGE="${1:-local/devcontainer:devcontainer-standard}"

echo "Testing image: $IMAGE"
echo ""

# Run test in container
docker run --rm -it "$IMAGE" /bin/bash -c '
echo "1. Testing mise availability:"
which mise || echo "mise not found"
mise --version 2>/dev/null || echo "mise version failed"
echo ""

echo "2. Testing starship in zsh:"
zsh -l -c "which starship || echo \"starship not found in zsh\""
echo ""

echo "3. Checking .zshrc for starship init:"
grep -n "starship init" ~/.zshrc 2>/dev/null || echo "No starship init in .zshrc"
echo ""

echo "4. Testing if starship prompt works:"
zsh -l -c "echo \$STARSHIP_SHELL || echo \"STARSHIP_SHELL not set\""
echo ""

echo "5. Checking devcontainer marker:"
grep "DEVCONTAINER_CONFIG_APPLIED" ~/.zshrc 2>/dev/null && echo "Devcontainer config found" || echo "Devcontainer config NOT found"
echo ""

echo "6. Testing aliases:"
zsh -l -c "alias | grep -E \"(ls|cat|ll)\" || echo \"No aliases found\""
'

echo ""
echo "=== Test Complete ===