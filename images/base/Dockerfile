# Base stage with common dependencies
FROM buildpack-deps:bookworm AS base

# Update package lists
RUN apt-get update -y
RUN apt-get install -y apt-utils lsb-release

# Environment setup
ENV DEBIAN_FRONTEND=noninteractive \
  LANG=C.UTF-8 \
  LC_ALL=C.UTF-8 \
  SCRIPTS_FOLDER=/tmp/scripts
COPY scripts /tmp/scripts
RUN chmod -R +x ${SCRIPTS_FOLDER}

# Install apt-fast for faster package downloads
ARG APT_FAST=true
RUN if [ "$APT_FAST" = "true" ]; then ${SCRIPTS_FOLDER}/setup/apt-fast.sh; fi

# Setup the system
RUN ${SCRIPTS_FOLDER}/setup/system.sh

RUN cp ${SCRIPTS_FOLDER}/entrypoint.sh /usr/local/bin/entrypoint.sh && \
  chmod +x /usr/local/bin/entrypoint.sh

# User configuration
ARG USERNAME=zero
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG PASSWORDLESS_SUDO=true
ENV HOME=/home/$USERNAME \
  USERNAME=$USERNAME \
  USER_UID=$USER_UID \
  USER_GID=$USER_GID \
  PASSWORDLESS_SUDO=$PASSWORDLESS_SUDO
RUN ${SCRIPTS_FOLDER}/setup/user.sh
WORKDIR $HOME
USER $USERNAME

# Setup shell configs
RUN ${SCRIPTS_FOLDER}/setup/shell.sh ${USERNAME}

# Cleanup
USER root
RUN ${SCRIPTS_FOLDER}/helpers/cleanup.sh

# Setup container for running
USER $USERNAME
ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
CMD []
