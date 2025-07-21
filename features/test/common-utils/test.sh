#!/bin/bash

# This test file will be executed against an auto-generated devcontainer.json
# that includes the common-utils feature with default options
set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# Test that default shell is zsh
check "default-shell" bash -c "getent passwd $(whoami) | cut -d: -f7 | grep -q '/bin/zsh'"

# Test modern CLI tools are installed
check "starship" which starship
check "zoxide" which zoxide  
check "eza" which eza
check "bat" which bat

# Test web dev bundle tools
check "httpie" which http
check "jq" which jq
check "yq" which yq
check "dasel" which dasel
check "postgresql-client" which psql
check "mysql-client" which mysql
check "sqlite3" which sqlite3

# Test networking bundle tools
check "curl" which curl
check "wget" which wget
check "nmap" which nmap
check "netcat" which nc
check "iperf3" which iperf3

# Test utilities bundle tools  
check "git" which git
check "gh" which gh
check "lazygit" which lazygit
check "fd" which fd
check "ripgrep" which rg
check "htop" which htop
check "tlrc" which tlrc

# Test shell configs exist
check "bashrc" test -f ~/.bashrc
check "zshrc" test -f ~/.zshrc

# Test config files exist
check "starship-config" test -f ~/.config/starship.toml
check "motd-script" test -f ~/.config/modern-shell-motd.sh
check "ssh-config" test -f ~/.ssh/config
check "git-config" test -f ~/.gitconfig

# Test that our configuration was appended with markers
check "bashrc-markers" bash -c "grep -q '# >>> Modern Shell Tools - START >>>' ~/.bashrc"
check "zshrc-markers" bash -c "grep -q '# >>> Modern Shell Tools - START >>>' ~/.zshrc"

# Test completion directories exist
check "bash-completions-dir" test -d ~/.local/share/bash-completion/completions
check "zsh-completions-dir" test -d ~/.local/share/zsh/site-functions

# Test shim scripts are installed
check "code-shim" test -x /usr/local/bin/code
check "systemctl-shim" test -x /usr/local/bin/systemctl  
check "devcontainer-info" test -x /usr/local/bin/devcontainer-info

# Test aliases work in bash
check "eza-alias-bash" bash -c "source ~/.bashrc && alias ls | grep -q 'eza'"
check "bat-alias-bash" bash -c "source ~/.bashrc && alias cat | grep -q 'bat'"
check "tldr-alias-bash" bash -c "source ~/.bashrc && alias tldr | grep -q 'tlrc'"

# Report results
reportResults