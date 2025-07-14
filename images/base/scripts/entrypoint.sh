#!/bin/sh

sudo /usr/bin/supervisord -c /etc/supervisor/supervisord.conf -n >> /dev/null 2>&1 &

echo "Starting docker..."
while ! pgrep "dockerd" >/dev/null; do
  sleep 1
done

# Make zero the owner of the docker socket
sudo chown zero:zero /usr/local/bin/docker-compose
sudo chown zero:zero /var/run/docker.sock

if [ -n "$TERM" ]; then
  tput cr
  reset -I
fi

exec "$@" 