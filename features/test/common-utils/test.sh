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
check "sqlite3" which sqlite3
check "redis-cli" which redis-cli

# Test networking bundle tools
check "curl" which curl
check "wget" which wget
check "nmap" which nmap
check "netcat" which nc
check "iperf3" which iperf3

# Test utilities bundle tools
check "git" which git
check "gh" which gh
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

# Test that our configuration was appended with new common-utils markers
check "bashrc-markers" bash -c "grep -q '# >>> common-utils - START >>>' ~/.bashrc"
check "zshrc-markers" bash -c "grep -q '# >>> common-utils - START >>>' ~/.zshrc"
check "bashrc-end-markers" bash -c "grep -q '# <<< common-utils - END <<<' ~/.bashrc"
check "zshrc-end-markers" bash -c "grep -q '# <<< common-utils - END <<<' ~/.zshrc"

# Test that zshenv and bash_profile files were created and configured
check "zshenv-exists" test -f ~/.zshenv
check "zshenv-markers" bash -c "grep -q '# >>> common-utils - START >>>' ~/.zshenv"
check "bash-profile-exists" test -f ~/.bash_profile
check "bash-profile-markers" bash -c "grep -q '# >>> common-utils - START >>>' ~/.bash_profile"

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

# Test specific tool configurations are present in shell files
check "starship-in-bashrc" bash -c "grep -q 'starship init' ~/.bashrc"
check "starship-in-zshrc" bash -c "grep -q 'starship init' ~/.zshrc"
check "zoxide-in-bashrc" bash -c "grep -q 'zoxide init' ~/.bashrc"
check "zoxide-in-zshrc" bash -c "grep -q 'zoxide init' ~/.zshrc"

# Test that eza aliases are present
check "eza-ls-alias-bashrc" bash -c "grep -q \"alias ls='eza'\" ~/.bashrc"
check "eza-ls-alias-zshrc" bash -c "grep -q \"alias ls='eza'\" ~/.zshrc"

# Test that bat alias is present
check "bat-cat-alias-bashrc" bash -c "grep -q \"alias cat='bat --paging=never'\" ~/.bashrc"
check "bat-cat-alias-zshrc" bash -c "grep -q \"alias cat='bat --paging=never'\" ~/.zshrc"

# Test that completion configurations are present
check "completion-config-bashrc" bash -c "grep -q 'bash-completion/completions' ~/.bashrc"
check "completion-config-zshrc" bash -c "grep -q 'zsh/site-functions' ~/.zshrc"

# Test that configurations are within markers (not duplicate)
check "single-starship-section-bashrc" bash -c "[ $(grep -c 'starship init' ~/.bashrc) -eq 1 ]"
check "single-starship-section-zshrc" bash -c "[ $(grep -c 'starship init' ~/.zshrc) -eq 1 ]"

# Report results
reportResults
