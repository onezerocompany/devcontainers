FROM debian:bookworm-slim

RUN apt update
RUN apt install -y --no-install-recommends \
  net-tools \
  iproute2 \
  iputils-ping \
  vim \
  procps \
  zsh \
  sudo

RUN adduser coder && \
  usermod -aG sudo coder && \
  echo "coder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
  echo "coder:coder" | chpasswd

RUN echo "PROMPT='> '" >> /etc/zsh/zshrc && \
  echo "alias ll='ls -l'" >> /etc/zsh/zshrc && \
  touch /home/coder/.zshrc

# Set the default shell to zsh
RUN chsh -s /bin/zsh coder

# cleanup
RUN apt clean -y && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

USER coder

CMD ["/bin/zsh"]