# Bat aliases (modern cat with syntax highlighting)
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
    alias less='bat --paging=always'
    alias more='bat --paging=always'
fi