#!/bin/bash -e

INSTALL=${INSTALL:-"true"}
if [ "$INSTALL" != "true" ]; then
  echo "Skipping Trivy installation"
  exit 0
fi

wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | tee -a /etc/apt/sources.list.d/trivy.list
apt-get update -y
apt-get install -y trivy