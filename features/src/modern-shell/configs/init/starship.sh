# Starship - Cross-shell prompt (interactive shells only)
if command -v starship >/dev/null 2>&1 && [[ $- == *i* ]]; then
    eval "$(starship init {{SHELL}})"
fi