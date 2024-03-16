FROM ghcr.io/actions/actions-runner:latest

# Install apt-fast
RUN /bin/bash -c "$(curl -sL https://git.io/vokNn)"

RUN sudo apt-get update && \
    sudo apt-get -y upgrade && \
    sudo apt-get -y install \
    zsh curl wget git unzip tar zip xz-utils \
    build-essential make cmake \
    libglu1-mesa \
    python3 python3-pip python3-venv \
    clang ninja-build pkg-config libgtk-3-dev liblzma-dev scrcpy default-jre

# Make zsh default shell
RUN sudo chsh -s $(which zsh)
SHELL ["/bin/zsh", "-c"]

# JavaScript / TypeScript
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash && \
    export NVM_DIR="$HOME/.nvm" && \
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
    nvm install --lts --latest-npm --default && \
    npm install -g yarn pnpm

# Install bun
RUN curl -fsSL https://bun.sh/install | bash