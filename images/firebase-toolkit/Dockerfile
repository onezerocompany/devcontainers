# Use the official Alpine Linux image
FROM --platform=linux/amd64 alpine:latest

RUN apk update && \
    apk add --no-cache \
    bash \
    curl \
    openjdk11-jdk \
    nodejs \
    npm

RUN npm install -g firebase-tools

# pre-download the emulators
RUN firebase setup:emulators:firestore && \
    firebase setup:emulators:database && \
    firebase setup:emulators:pubsub && \
    firebase setup:emulators:storage && \
    firebase setup:emulators:ui

RUN mkdir /emulators
WORKDIR /emulators

ADD entrypoint.sh .
RUN chmod +x entrypoint.sh

VOLUME [ "/data" ]
CMD ["./entrypoint.sh"]