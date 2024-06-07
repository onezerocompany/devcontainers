#!/bin/sh

sudo /usr/bin/supervisord -c /etc/supervisor/supervisord.conf -n >> /dev/null 2>&1 &


echo "Starting docker..."
while ! pgrep "dockerd" >/dev/null; do
  sleep 1
done

echo "Fixing permissions..."
sudo chown root:docker /var/run/docker.sock

tput cr
reset -I

exec "$@" 