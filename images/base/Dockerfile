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
    apt-fast -y install \
    curl wget sudo gpg nano vim \
    zsh git unzip zip tar xz-utils \
    jq ca-certificates lsb-release \
    build-essential make cmake libglu1-mesa \
    python3 python3-pip python3-venv \
    libc6 libgcc1 libgssapi-krb5-2 \
    libicu70 libssl3 libstdc++6 zlib1g \
    skopeo

RUN useradd -m zero && \
    echo "zero:zero" | chpasswd && adduser zero sudo && \
    echo "zero ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    
RUN chsh -s /bin/zsh && \
    chsh -s /bin/zsh zero && \
    chown -R zero:zero /home/zero

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