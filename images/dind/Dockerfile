FROM ghcr.io/onezerocompany/base:latest

USER root

COPY install-docker.sh .
RUN bash ./install-docker.sh && rm install-docker.sh

COPY modprobe entrypoint.sh /usr/local/bin/ 
RUN chmod +x /usr/local/bin/entrypoint.sh \
	/usr/local/bin/modprobe

COPY supervisor/ /etc/supervisor/conf.d/

VOLUME /var/lib/docker
USER zero

ENTRYPOINT ["entrypoint.sh"]
CMD ["bash"]