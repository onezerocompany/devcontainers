#!/bin/bash

set -e
source "${SCRIPTS_FOLDER}/helpers/utils.sh"

# Install sudo for user privilege escalation
install_packages sudo jq sed ripgrep fd-find tree

upgrade_packages
