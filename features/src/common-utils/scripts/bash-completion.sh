#!/bin/bash
# Install bash completion
set -e

echo "  🔧 Installing bash completion..."

apt-get install -y bash-completion

# Enable bash completion in bashrc if not already enabled
if ! grep -q "/etc/bash_completion" /etc/bash.bashrc 2>/dev/null; then
    echo "# Enable bash completion" >> /etc/bash.bashrc
    echo "if [ -f /etc/bash_completion ] && ! shopt -oq posix; then" >> /etc/bash.bashrc
    echo "    . /etc/bash_completion" >> /etc/bash.bashrc
    echo "fi" >> /etc/bash.bashrc
fi

echo "  ✓ Bash completion installed"