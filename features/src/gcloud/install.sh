#!/bin/bash -e

USER=${USER:-"zero"}
VERSION=${VERSION:-"latest"}

# Function to fetch the latest version information
get_latest_version() {
  curl -s https://raw.githubusercontent.com/google-github-actions/setup-cloud-sdk/main/data/versions.json | \
  jq '.[-1]' | tr -d '"'
}

if [ "$VERSION" = "latest" ]; then
  gcloud_version=$(get_latest_version)
else
  gcloud_version=$VERSION
fi

arch=$(uname -m)
case $arch in
  x86_64)
    arch="x86_64"
    ;;
  aarch64)
    arch="arm"
    ;;
  *)
    echo "Unsupported architecture: $arch"
    exit 1
    ;;
esac

# download to /tmp/gcloud-cli.tar.gz
DOWNLOAD_URL=https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-$gcloud_version-linux-$arch.tar.gz
wget -q -O /tmp/gcloud-cli.tar.gz $DOWNLOAD_URL

mkdir -p /opt/gcloud

# extract to /opt
tar -xzf /tmp/gcloud-cli.tar.gz -C /opt/gcloud

# Add gcloud to PATH
echo "export PATH=\$PATH:/opt/gcloud/google-cloud-sdk/bin" >> /home/$USER/.zshrc
echo "export PATH=\$PATH:/opt/gcloud/google-cloud-sdk/bin" >> /home/$USER/.bashrc

# Cleanup
rm -rf /tmp/gcloud-cli.tar.gz