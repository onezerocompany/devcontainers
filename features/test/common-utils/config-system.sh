#!/bin/bash

# Test the new common-utils configuration system
# This test verifies that the tmp file approach works correctly

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Test that temporary files don't persist after installation
check "tmp-bashrc-cleaned" bash -c "! test -f /tmp/tmp_bashrc"
check "tmp-zshrc-cleaned" bash -c "! test -f /tmp/tmp_zshrc"
check "tmp-zshenv-cleaned" bash -c "! test -f /tmp/tmp_zshenv"
check "tmp-bash-profile-cleaned" bash -c "! test -f /tmp/tmp_bash_profile"

# Test that common-utils markers exist in shell files
check "bashrc-common-utils-start" bash -c "grep -q '# >>> common-utils - START >>>' ~/.bashrc"
check "bashrc-common-utils-end" bash -c "grep -q '# <<< common-utils - END <<<' ~/.bashrc"
check "bash-profile-common-utils-start" bash -c "grep -q '# >>> common-utils - START >>>' ~/.bash_profile"
check "bash-profile-common-utils-end" bash -c "grep -q '# <<< common-utils - END <<<' ~/.bash_profile"
check "zshrc-common-utils-start" bash -c "grep -q '# >>> common-utils - START >>>' ~/.zshrc"
check "zshrc-common-utils-end" bash -c "grep -q '# <<< common-utils - END <<<' ~/.zshrc"
check "zshenv-common-utils-start" bash -c "grep -q '# >>> common-utils - START >>>' ~/.zshenv"
check "zshenv-common-utils-end" bash -c "grep -q '# <<< common-utils - END <<<' ~/.zshenv"

# Test that only one common-utils section exists in each file
check "single-common-utils-section-bashrc" bash -c "[ $(grep -c '# >>> common-utils - START >>>' ~/.bashrc) -eq 1 ]"
check "single-common-utils-section-bash-profile" bash -c "[ $(grep -c '# >>> common-utils - START >>>' ~/.bash_profile) -eq 1 ]"
check "single-common-utils-section-zshrc" bash -c "[ $(grep -c '# >>> common-utils - START >>>' ~/.zshrc) -eq 1 ]"
check "single-common-utils-section-zshenv" bash -c "[ $(grep -c '# >>> common-utils - START >>>' ~/.zshenv) -eq 1 ]"

# Test that the section contains expected content
check "starship-config-present" bash -c "sed -n '/# >>> common-utils - START >>>/,/# <<< common-utils - END <<</p' ~/.bashrc | grep -q 'starship init'"
check "zoxide-config-present" bash -c "sed -n '/# >>> common-utils - START >>>/,/# <<< common-utils - END <<</p' ~/.zshrc | grep -q 'zoxide init'"
check "eza-config-present" bash -c "sed -n '/# >>> common-utils - START >>>/,/# <<< common-utils - END <<</p' ~/.bashrc | grep -q \"alias ls='eza'\""
check "bat-config-present" bash -c "sed -n '/# >>> common-utils - START >>>/,/# <<< common-utils - END <<</p' ~/.zshrc | grep -q \"alias cat='bat --paging=never'\""

# Test that configurations are not duplicated outside the markers
check "no-duplicate-starship" bash -c "[ $(grep -c 'starship init' ~/.bashrc) -eq 1 ]"
check "no-duplicate-zoxide" bash -c "[ $(grep -c 'zoxide init' ~/.zshrc) -eq 1 ]"
check "no-duplicate-eza-alias" bash -c "[ $(grep -c \"alias ls='eza'\" ~/.bashrc) -eq 1 ]"
check "no-duplicate-bat-alias" bash -c "[ $(grep -c \"alias cat='bat --paging=never'\" ~/.zshrc) -eq 1 ]"

# Test zshenv contains basic environment configuration
check "zshenv-has-path-config" bash -c "grep -q 'PATH.*local/bin' ~/.zshenv"
check "zshenv-has-editor-config" bash -c "grep -q 'EDITOR' ~/.zshenv"

# Test bash_profile contains expected content
check "bash-profile-sources-bashrc" bash -c "grep -q 'source.*bashrc' ~/.bash_profile"

# Test that marker format is consistent
check "marker-format-consistent" bash -c "grep -q '# Added by common-utils feature' ~/.bashrc"

# Report results
reportResults