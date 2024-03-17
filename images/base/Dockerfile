FROM debian:bookworm-slim

# Install apt-fast
RUN /bin/bash -c "$(curl -sL https://git.io/vokNn)"

# Install default packages
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install \
    zsh curl wget git unzip zip tar xz-utils \
    # docker-in-docker dependencies
    fuse-overlayfs iptables libltdl7 \
    btrfs-progs e2fsprogs xfsprogs xz-utils 

# Make zsh default shell
RUN chsh -s $(which zsh)
SHELL ["/bin/zsh", "-c"]

RUN set -eux; \
	mkdir -p /usr/local/sbin/.iptables-legacy; \
	for f in \
		iptables \
		iptables-save \
		iptables-restore \
		ip6tables \
		ip6tables-save \
		ip6tables-restore \
	; do \
		b="/sbin/${f/tables/tables-legacy}"; \
		"$b" --version; \
		ln -svT "$b" "/usr/local/sbin/.iptables-legacy/$f"; \
	done; \
	export PATH="/usr/local/sbin/.iptables-legacy:$PATH"; \
	iptables --version | grep legacy

# set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
RUN set -eux; \
	addgroup -S dockremap; \
	adduser -S -G dockremap dockremap; \
	echo 'dockremap:165536:65536' >> /etc/subuid; \
	echo 'dockremap:165536:65536' >> /etc/subgid

RUN set -eux; \
	\
	apkArch="$(apk --print-arch)"; \
	case "$apkArch" in \
		'x86_64') \
			url='https://download.docker.com/linux/static/stable/x86_64/docker-25.0.4.tgz'; \
			;; \
		'armhf') \
			url='https://download.docker.com/linux/static/stable/armel/docker-25.0.4.tgz'; \
			;; \
		'armv7') \
			url='https://download.docker.com/linux/static/stable/armhf/docker-25.0.4.tgz'; \
			;; \
		'aarch64') \
			url='https://download.docker.com/linux/static/stable/aarch64/docker-25.0.4.tgz'; \
			;; \
		*) echo >&2 "error: unsupported 'docker.tgz' architecture ($apkArch)"; exit 1 ;; \
	esac; \
	\
	wget -O 'docker.tgz' "$url"; \
	\
	tar --extract \
		--file docker.tgz \
		--strip-components 1 \
		--directory /usr/local/bin/ \
		--no-same-owner \
# we exclude the CLI binary because we already extracted that over in the "docker:25-cli" image that we're FROM and we don't want to duplicate those bytes again in this layer
		--exclude 'docker/docker' \
	; \
	rm docker.tgz; \
	\
	dockerd --version; \
	containerd --version; \
	ctr --version; \
	runc --version

# https://github.com/docker/docker/tree/master/hack/dind
ENV DIND_COMMIT 65cfcc28ab37cb75e1560e4b4738719c07c6618e

RUN set -eux; \
	wget -O /usr/local/bin/dind "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind"; \
	chmod +x /usr/local/bin/dind

COPY dockerd-entrypoint.sh /usr/local/bin/

VOLUME /var/lib/docker
EXPOSE 2375 2376

ENTRYPOINT [ "dockerd-entrypoint.sh" ]
CMD []