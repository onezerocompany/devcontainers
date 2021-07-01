#!/bin/sh
NODE_VERSION=$1
ARCH=
alpineArch="$(apk --print-arch)"
case "${alpineArch##*-}" in \
  x86_64) \
    ARCH='x64' \
  ;; \
  *) ;; \
  esac
curl -fsSLO --compressed "https://unofficial-builds.nodejs.org/download/release/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH-musl.tar.xz"
tar -xJf "node-v$NODE_VERSION-linux-$ARCH-musl.tar.xz" -C /usr/local --strip-components=1 --no-same-owner
ln -s /usr/local/bin/node /usr/local/bin/nodejs
  
rm -f "node-v$NODE_VERSION-linux-$ARCH-musl.tar.xz"
node --version
npm --version