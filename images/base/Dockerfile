FROM ubuntu:22.04

ENV \
    ASPNETCORE_URLS=http://+:80 \
    DOTNET_RUNNING_IN_CONTAINER=true

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y && \
    apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:git-core/ppa && \
    add-apt-repository -y ppa:apt-fast/stable && \
    apt-get update -y && \
    apt-get install -y apt-fast

RUN apt-fast -y upgrade && \
    apt-fast update -y && \
    apt-fast -y install \
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
        lsb-release \
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
        zlib1g zlib1g-dev \
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
        gnome-keyring

RUN useradd -m zero && \
    echo "zero:zero" | chpasswd && adduser zero sudo && \
    echo "zero ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    
RUN chsh -s /bin/zsh && \
    chsh -s /bin/zsh zero && \
    chown -R zero:zero /home/zero

RUN \
    echo "autoload -Uz compinit" >> /home/zero/.zshrc && \ 
    echo "compinit" >> /home/zero/.zshrc

COPY prompt.sh /home/zero/.zsh/prompt.sh
RUN chown zero:zero /home/zero/.zsh/prompt.sh && \
    chmod +x /home/zero/.zsh/prompt.sh && \
    echo "setopt PROMPT_SUBST" >> /home/zero/.zshrc && \
    cat /home/zero/.zsh/prompt.sh >> /home/zero/.zshrc && \
    echo "" >> /home/zero/.zshrc && \
    rm /home/zero/.zsh/prompt.sh && \
    echo "alias apt-get='apt-fast'" >> /home/zero/.zshrc && \
    chown zero:zero /home/zero/.zshrc

WORKDIR /home/zero
USER zero

RUN touch ~/.sudo_as_admin_successful

CMD ["/bin/zsh"]