# Zoxide - Smart cd command
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init {{SHELL}})"
fi