#!/bin/bash
# Common functions used by all the scripts

APT_CMD="apt-get"
if [ -x "$(command -v apt-fast)" ]; then
    APT_CMD="apt-fast"
fi

install_packages() {
    $APT_CMD install -y $@
}

upgrade_packages() {
    $APT_CMD upgrade -y
}
