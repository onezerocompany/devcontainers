# Zoxide - Smarter cd command (interactive shells only)
if command -v zoxide >/dev/null 2>&1 && [[ $- == *i* ]]; then
    eval "$(zoxide init {{SHELL}})"
fi