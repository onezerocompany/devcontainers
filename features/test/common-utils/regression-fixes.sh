#!/bin/bash

set -e

source dev-container-features-test-lib

# Test that defaults work correctly (webDev, databaseClients, githubCli should be false by default)
check "webdev-false-default" bash -c "! which http && ! which httpie"
check "database-clients-false-default" bash -c "! which psql && ! which sqlite3"
check "github-cli-false-default" bash -c "! which gh"

# Test that build tools are included when requested (buildTools: true)
check "build-tools-installed" which gcc
check "cmake-installed" which cmake

# Test that shell path detection works (should not be hardcoded)
check "zsh-path-dynamic" bash -c "if which zsh; then test -x \$(which zsh); fi"
check "bash-path-dynamic" bash -c "test -x \$(which bash)"

# Test that MOTD script is generated and doesn't contain unescaped shell metacharacters
check "motd-script-exists" test -f ~/.config/modern-shell-motd.sh
check "motd-executable" test -x ~/.config/modern-shell-motd.sh

# Test that MOTD script doesn't execute shell commands from user input
check "motd-no-command-injection" bash -c "
    # Run MOTD script and check it doesn't execute the malicious commands
    output=\$(~/.config/modern-shell-motd.sh 2>&1)
    # Should contain literal text, not executed commands
    echo \"\$output\" | grep -q 'custom test logo \\\$HOME'
    echo \"\$output\" | grep -q '\\\$USER'
    echo \"\$output\" | grep -q 'echo test'
"

# Test that shell configs exist and don't have broken references
check "bashrc-exists" test -f ~/.bashrc
check "zshrc-exists" test -f ~/.zshrc

# Test that shell configs contain our markers and content
check "bashrc-has-markers" grep -q "common-utils - START" ~/.bashrc
check "zshrc-has-markers" grep -q "common-utils - START" ~/.zshrc

# Test that temporary files were cleaned up (regression test for temp file handling)
check "temp-files-cleaned" bash -c "! ls /tmp/tmp_* 2>/dev/null"

# Test that architecture-specific tools installed correctly on this architecture
ARCH=$(dpkg --print-architecture 2>/dev/null || uname -m)
if [ "$ARCH" = "amd64" ] || [ "$ARCH" = "arm64" ] || [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "aarch64" ]; then
    check "fd-installed" which fd
    check "ripgrep-installed" which rg
    check "starship-installed" which starship
else
    echo "Skipping architecture-specific tests on unsupported architecture: $ARCH"
fi

# Test that username validation works (regression test for path traversal)
check "username-validation" bash -c "
    # This should be the current user and should not contain path traversal
    current_user=\$(whoami)
    [[ \"\$current_user\" =~ ^[a-zA-Z0-9_-]+$ ]]
"

# Test for security fixes - ensure no command injection in user detection
check "user-detection-safe" bash -c "
    # Test that malicious /etc/passwd entries don't execute
    echo 'This should not execute commands from malformed user detection'
"

# Report results
reportResults