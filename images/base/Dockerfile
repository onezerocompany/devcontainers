# Base stage with common dependencies
FROM ubuntu:22.04 AS base

ENV ASPNETCORE_URLS=http://+:80
ENV DOTNET_RUNNING_IN_CONTAINER=true
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN apt-get update -y && \
    apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:git-core/ppa && \
    add-apt-repository -y ppa:apt-fast/stable && \
    apt-get update -y && \
    apt-get install -y apt-fast

# Split upgrade and install to avoid QEMU issues on ARM64
RUN apt-get upgrade -y || true

# Install packages in smaller groups to reduce memory pressure
RUN apt-get install -y \
        curl \
        wget \
        sudo \
        gpg \
        nano \
        vim \
        zsh \
        git \
        zip unzip \
        tar xz-utils \
        jq \
        ca-certificates \
        lsb-release

RUN apt-get install -y \
        build-essential \
        make \
        cmake \
        libglu1-mesa \
        libc6 libc6-dev \
        libgcc1 libgcc-9-dev \
        libgssapi-krb5-2 \
        libicu70 \
        libssl3 \
        libstdc++6 \
        zlib1g zlib1g-dev

RUN apt-get install -y \
        skopeo \
        binutils \
        gnupg2 \
        libcurl4-openssl-dev \
        libedit2 \
        libpython3.8 \
        libsqlite3-0 \
        libstdc++-9-dev \
        libxml2-dev \
        libz3-dev \
        pkg-config \
        tzdata \
        gnome-keyring \
        python3-minimal

RUN apt-get install -y supervisor iptables \
    && update-alternatives --set iptables /usr/sbin/iptables-legacy

# Allow customizing the username at build time
ARG USERNAME=zero
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create user with configurable name
RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    
RUN chsh -s /bin/zsh && \
    chsh -s /bin/zsh $USERNAME && \
    chown -R $USERNAME:$USERNAME /home/$USERNAME

# Create a minimal .zshrc with just the essentials
RUN echo '# Ensure mise tools are available in all contexts' > /home/$USERNAME/.zshrc && \
    echo '# Source .zshenv to get PATH setup if not already done' >> /home/$USERNAME/.zshrc && \
    echo 'if [[ ! "$PATH" =~ "$HOME/.local/bin" ]]; then' >> /home/$USERNAME/.zshrc && \
    echo '    source ~/.zshenv' >> /home/$USERNAME/.zshrc && \
    echo 'fi' >> /home/$USERNAME/.zshrc && \
    echo '' >> /home/$USERNAME/.zshrc && \
    echo '# Zsh completion system' >> /home/$USERNAME/.zshrc && \
    echo 'autoload -Uz compinit' >> /home/$USERNAME/.zshrc && \
    echo 'compinit' >> /home/$USERNAME/.zshrc && \
    echo '' >> /home/$USERNAME/.zshrc && \
    echo '# Basic aliases' >> /home/$USERNAME/.zshrc && \
    echo "alias apt-get='apt-fast'" >> /home/$USERNAME/.zshrc && \
    echo '' >> /home/$USERNAME/.zshrc && \
    echo '# Mise activation (tool management)' >> /home/$USERNAME/.zshrc && \
    echo 'if [ -f "$HOME/.local/bin/mise" ]; then' >> /home/$USERNAME/.zshrc && \
    echo '    eval "$($HOME/.local/bin/mise activate zsh)"' >> /home/$USERNAME/.zshrc && \
    echo 'fi' >> /home/$USERNAME/.zshrc

# Also set up .zshenv for non-interactive shells
RUN echo '# Path configuration for non-interactive shells' > /home/$USERNAME/.zshenv && \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> /home/$USERNAME/.zshenv && \
    echo '' >> /home/$USERNAME/.zshenv && \
    echo '# Source mise env for non-interactive shells' >> /home/$USERNAME/.zshenv && \
    echo 'if [ -f "$HOME/.local/bin/mise" ]; then' >> /home/$USERNAME/.zshenv && \
    echo '    eval "$($HOME/.local/bin/mise activate zsh --shims)"' >> /home/$USERNAME/.zshenv && \
    echo 'fi' >> /home/$USERNAME/.zshenv

# Also set up .zprofile for login shells
RUN echo '# Path configuration for login shells' > /home/$USERNAME/.zprofile && \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> /home/$USERNAME/.zprofile && \
    echo '' >> /home/$USERNAME/.zprofile && \
    echo '# Source mise env for login shells' >> /home/$USERNAME/.zprofile && \
    echo 'if [ -f "$HOME/.local/bin/mise" ]; then' >> /home/$USERNAME/.zprofile && \
    echo '    eval "$($HOME/.local/bin/mise activate zsh --shims)"' >> /home/$USERNAME/.zprofile && \
    echo 'fi' >> /home/$USERNAME/.zprofile

RUN chown $USERNAME:$USERNAME /home/$USERNAME/.zshrc /home/$USERNAME/.zshenv /home/$USERNAME/.zprofile

WORKDIR /home/$USERNAME
USER $USERNAME
ENV HOME=/home/$USERNAME

# Install mise as non-root user
RUN curl -fsSL https://mise.run | sh

# Set up mise environment variables for caching - using ENV expansion at runtime
ENV MISE_CACHE_DIR=$HOME/.cache/mise
ENV MISE_DATA_DIR=$HOME/.local/share/mise
ENV PATH="$HOME/.local/bin:${PATH}"

# Configure mise to auto-trust config files
ENV MISE_TRUSTED_CONFIG_PATHS="/"
ENV MISE_YES=1

# Create bash config for mise
RUN echo 'eval "$($HOME/.local/bin/mise activate bash)"' > ~/.bashrc

# Create mise cache directories
RUN mkdir -p ~/.cache/mise && \
    mkdir -p ~/.local/share/mise

# Copy global mise configuration and install tools
COPY --chown=$USERNAME:$USERNAME mise-global.toml /home/$USERNAME/.mise.toml
# Add retry logic for mise install to handle network timeouts
RUN for i in 1 2 3; do \
        echo "Attempt $i: Installing mise tools..." && \
        mise install && break || \
        (echo "Failed attempt $i, retrying in 5 seconds..." && sleep 5); \
    done

RUN touch ~/.sudo_as_admin_successful

# Standard stage - no Docker-in-Docker
FROM base AS standard
CMD ["/bin/zsh"]

# Docker-in-Docker stage
FROM base AS dind

USER root

# Copy and install Docker
COPY install-docker.sh .
RUN bash ./install-docker.sh && rm install-docker.sh

# Copy Docker-related files
COPY modprobe entrypoint.sh /usr/local/bin/ 
RUN chmod +x /usr/local/bin/entrypoint.sh \
	/usr/local/bin/modprobe

# Copy supervisor configuration
COPY supervisor/ /etc/supervisor/conf.d/

# Create Docker volume
VOLUME /var/lib/docker

# Switch back to the configured user
USER $USERNAME

# Set Docker-specific entrypoint
ENTRYPOINT ["entrypoint.sh"]
CMD ["/bin/zsh"]