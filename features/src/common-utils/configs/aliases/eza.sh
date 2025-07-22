# Eza aliases (modern ls replacement)
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --color=auto --group-directories-first'
    alias ll='eza -l --color=auto --group-directories-first'
    alias la='eza -la --color=auto --group-directories-first'
    alias lt='eza --tree --color=auto --group-directories-first'
    alias l='eza --color=auto --group-directories-first'
fi