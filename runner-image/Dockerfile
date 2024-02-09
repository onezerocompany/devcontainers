FROM ghcr.io/onezerocompany/base

# Install git
RUN apt update && apt install -y --no-install-recommends \
  git \
  curl

# Install docker
RUN curl -fsSL https://get.docker.com | sh
