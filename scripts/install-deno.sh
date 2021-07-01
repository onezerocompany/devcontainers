#!/usr/bin/env sh

if [ $1 == "latest" ]; then
  curl -fsSL "https://github.com/denoland/deno/releases/latest/download/deno-x86_64-unknown-linux-gnu.zip" --output deno.zip
else
  curl -fsSL "https://github.com/denoland/deno/releases/download/v$1/deno-x86_64-unknown-linux-gnu.zip" --output deno.zip
fi
unzip deno.zip
rm deno.zip
chmod 755 deno
mv deno /bin/deno
echo "export DENO_INSTALL=\"$deno_install\"" > /home/dev/~.zshrc
echo "export PATH=\"\$DENO_INSTALL/bin:\$PATH\"" > /home/dev/~.zshrc