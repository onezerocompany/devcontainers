#!/bin/sh

sudo /usr/bin/supervisord -c /etc/supervisor/supervisord.conf -n >> /dev/null 2>&1 &


echo "Starting docker..."
while ! pgrep "dockerd" >/dev/null; do
  sleep 1
done

if [ -n "$TERM" ]; then
  tput cr
  reset -I
fi

exec "$@" 