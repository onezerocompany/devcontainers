#!/bin/bash
# Debug script for starship issues

echo "=== Starship Debug Info ==="
echo ""

echo "1. Current PATH:"
echo "$PATH"
echo ""

echo "2. Checking for mise:"
which mise || echo "mise not found in PATH"
echo ""

echo "3. Mise version:"
mise --version 2>/dev/null || echo "mise command failed"
echo ""

echo "4. Mise installed tools:"
mise ls --current 2>/dev/null || echo "mise ls failed"
echo ""

echo "5. Checking for starship in common locations:"
locations=(
    "$HOME/.local/bin/starship"
    "$HOME/.local/share/mise/installs/starship/latest/bin/starship"
    "/usr/local/bin/starship"
    "/usr/bin/starship"
)

for loc in "${locations[@]}"; do
    if [ -x "$loc" ]; then
        echo "Found: $loc"
        "$loc" --version
    fi
done
echo ""

echo "6. Which starship:"
which starship || echo "starship not found in PATH"
echo ""

echo "7. Current shell:"
echo "SHELL=$SHELL"
echo "Running: $(ps -p $$ -o comm=)"
echo ""

echo "8. Shell RC files:"
echo "~/.zshrc exists: $([ -f ~/.zshrc ] && echo "yes" || echo "no")"
echo "~/.bashrc exists: $([ -f ~/.bashrc ] && echo "yes" || echo "no")"
echo ""

echo "9. Checking if starship init is in shell RC:"
grep -n "starship init" ~/.zshrc 2>/dev/null || echo "No starship init found in .zshrc"
echo ""

echo "10. Environment variables:"
env | grep -E "(MISE|STARSHIP|PATH)" | sort
echo ""

echo "=== End Debug Info ==="