FROM debian:bookworm-slim

# Install apt-fast
RUN /bin/bash -c "$(curl -sL https://git.io/vokNn)"

# Install default packages
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install \
    zsh curl wget git unzip zip tar xz-utils \
    # Install docker-in-docker dependencies
    uidmap iptables iproute2 \
    apt-transport-https ca-certificates gnupg lsb-release \
    libseccomp2 slirp4netns fuse-overlayfs

# Make zsh default shell
RUN chsh -s $(which zsh)
SHELL ["/bin/zsh", "-c"]

COPY scripts /scripts
RUN chmod +x /scripts/*

# Setup user
RUN /scripts/setup-user.sh
RUN rm -rf /scripts

USER runner
# --- all below will be run as user ---

# Install docker-in-docker using setup script
RUN 
RUN curl -fsSL https://get.docker.com/rootless | sh