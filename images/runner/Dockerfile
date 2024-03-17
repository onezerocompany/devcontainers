FROM ghcr.io/onezerocompany/base:latest

RUN apt-get -y install \
    build-essential make cmake libglu1-mesa \
    python3 python3-pip python3-venv

# JavaScript / TypeScript
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash && \
    export NVM_DIR="$HOME/.nvm" && \
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
    nvm install --lts --latest-npm --default && \
    npm install -g yarn pnpm

# Install bun
RUN curl -fsSL https://bun.sh/install | bash