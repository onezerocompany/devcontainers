# Buildpack-deps:bookworm Bill of Materials (BOM)

This document provides a comprehensive list of all packages included in the `buildpack-deps:bookworm` Docker image.

## Image Hierarchy

The buildpack-deps image is built in layers:
1. `debian:bookworm` (base Debian 12)
2. `buildpack-deps:bookworm-curl` (adds networking tools)
3. `buildpack-deps:bookworm-scm` (adds source control tools)
4. `buildpack-deps:bookworm` (adds full development stack)

## Complete Package List

### Layer 1: buildpack-deps:bookworm-curl
**Networking and Certificate Tools:**
- ca-certificates
- curl
- gnupg
- netbase
- sq
- wget

### Layer 2: buildpack-deps:bookworm-scm
**Source Control Management:**
- git
- mercurial
- openssh-client
- subversion
- procps

### Layer 3: buildpack-deps:bookworm (Full)
**Build Tools:**
- autoconf
- automake
- bzip2
- dpkg-dev
- file
- g++
- gcc
- libtool
- make
- patch
- unzip
- xz-utils

**Database Development Libraries:**
- default-libmysqlclient-dev
- libdb-dev
- libevent-dev
- libpq-dev
- libsqlite3-dev

**System Libraries:**
- libbz2-dev
- libc6-dev
- libffi-dev
- libgdbm-dev
- libgmp-dev
- liblzma-dev
- libncurses5-dev
- libncursesw5-dev
- libreadline-dev
- zlib1g-dev

**Networking Libraries:**
- libcurl4-openssl-dev
- libkrb5-dev
- libssl-dev

**Graphics and Media Libraries:**
- imagemagick
- libjpeg-dev
- libmagickcore-dev
- libmagickwand-dev
- libpng-dev
- libwebp-dev

**Text and Data Processing:**
- libxml2-dev
- libxslt-dev
- libyaml-dev

**Other Libraries:**
- libglib2.0-dev
- libmaxminddb-dev

## Summary

The buildpack-deps:bookworm image includes:
- **6** networking and certificate tools
- **5** source control tools
- **12** build tools
- **5** database libraries
- **10** system libraries
- **3** networking libraries
- **6** graphics/media libraries
- **3** text processing libraries
- **2** miscellaneous libraries

**Total: 52 packages** pre-installed in buildpack-deps:bookworm

## Implications for Our Image

Since we're using buildpack-deps:bookworm as our base, we should NOT install:
- Basic tools: curl, wget, git, tar, xz-utils, ca-certificates, gnupg
- Build tools: gcc, g++, make, autoconf, automake, libtool, patch, file
- Development libraries: libssl-dev, libcurl4-openssl-dev, zlib1g-dev, libc6-dev
- Any of the other 52 packages listed above

We should focus on installing only:
- Tools not included (sudo, vim, nano, zsh, jq, bat, fzf, etc.)
- Modern CLI tools (starship, zoxide, eza)
- Container-specific tools (iptables)
- Runtime-specific tools (cmake, skopeo)