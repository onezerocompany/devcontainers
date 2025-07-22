# Mise tool version manager
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash)" 2>/dev/null || eval "$(mise activate zsh)" 2>/dev/null || true
fi