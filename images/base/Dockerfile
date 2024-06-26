FROM ubuntu:22.04

ENV \
    ASPNETCORE_URLS=http://+:80 \
    DOTNET_RUNNING_IN_CONTAINER=true

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y && \
    apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:git-core/ppa && \
    add-apt-repository -y ppa:apt-fast/stable && \
    apt-get update -y
    # apt-get install -y apt-fast

RUN apt-get upgrade -y && \
    apt-get install -y \
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
        gnome-keyring \
        python3-minimal

RUN apt-get install -y supervisor iptables \
    && update-alternatives --set iptables /usr/sbin/iptables-legacy

RUN useradd -m zero && \
    echo "zero:zero" | chpasswd && adduser zero sudo && \
    echo "zero ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    
RUN chsh -s /bin/zsh && \
    chsh -s /bin/zsh zero && \
    chown -R zero:zero /home/zero

RUN \
    echo "autoload -Uz compinit" >> /home/zero/.zshrc && \ 
    echo "compinit" >> /home/zero/.zshrc

RUN chown zero:zero /home/zero/.zsh/prompt.sh && \
    echo "" >> /home/zero/.zshrc && \
    rm /home/zero/.zsh/prompt.sh && \
    echo "alias apt-get='apt-fast'" >> /home/zero/.zshrc && \
    chown zero:zero /home/zero/.zshrc

WORKDIR /home/zero
USER zero

RUN touch ~/.sudo_as_admin_successful

CMD ["/bin/zsh"]