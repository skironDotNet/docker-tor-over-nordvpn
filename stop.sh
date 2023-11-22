#!/bin/bash

cd "${0%/*}" #go to dir where the script is located in case exec form a diffrent location

container_name=tor
if docker ps -a --format '{{.Names}}' | grep -Eq "^${container_name}\$"; then
  docker compose -f tor/docker-compose.yml down
else
  echo "*** TOR container doesn't seem to be running, assuming stopped."
fi

container_name=vpn
if docker ps -a --format '{{.Names}}' | grep -Eq "^${container_name}\$"; then
  docker compose -f vpn/docker-compose.yml down
else
  echo "*** VPN container doesn't seem to be running, assuming stopped."
fi

echo "*** Done!"

sleep 5 # wait before exit to let user read the output if executed directly 
