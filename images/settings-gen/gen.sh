#!/bin/sh

echo "Generating settings..."

# run dockerd-entrypoint.sh and wait for /var/run/docker.sock to be online
echo "Starting docker..."
dockerd-entrypoint.sh > /dev/null 2>&1 &

# wait for docker.sock to be available
while [ ! -e /var/run/docker.sock ]; do
  sleep 1
done

echo "Docker started."

# print docker config
cat /root/.docker/config.json

echo "Reading configuration..."
mkdir -p /vscode/settings
devcontainer read-configuration --workspace-folder /workspace --include-merged-configuration > /vscode/settings/merged-settings.json

# create extensions.json
jq '[.mergedConfiguration.customizations.vscode[].extensions] | map(select(. != null)) | add | unique' /vscode/settings/merged-settings.json > /vscode/settings/extensions.json

# create settings.json
jq '[.mergedConfiguration.customizations.vscode[].settings] | map(select(. != null)) | add' /vscode/settings/merged-settings.json > /vscode/settings/settings.json

echo "Settings generated."