#!/bin/bash

# Fetch the latest runner version from GitHub releases
latest_version=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | cut -c 2-)

# Save the fetched version to a file for use in the Dockerfile
echo $latest_version > /actions-runner/latest-runner-version
