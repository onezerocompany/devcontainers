#!/bin/sh
apk update
apk add --no-cache --virtual=.build-dependencies \
  wget curl unzip \
  ca-certificates