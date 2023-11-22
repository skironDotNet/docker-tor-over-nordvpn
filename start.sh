#!/bin/bash

# while single docker compose can be created there is no way to simply control the delay for tor to start or to check if VPN actually has connected
# so this script is first running the VPN, checks the connection not being home IP and then starts tor container
# another way would be to add tor to VPN container same way as all the init scripts are and create a script with IP check and re-try loop and run tor
# but from single process per container perspective it better to manage 2 separate containers IMO

cd "${0%/*}" #go to dir where the script is located in case exec form a diffrent location

function waitWithCounter() {
    seconds=$1
    for((i=1;i<=$1;++i)) do
        echo "*** $i"
        sleep 1s
    done
}

echoColor() {
    printf '\033[%sm%s\033[m\n' "$@"
    # usage color "31;5" "string"
    # 0 default
    # 5 blink, 1 strong, 4 underlined
    # fg: 31 red,  32 green, 33 yellow, 34 blue, 35 purple, 36 cyan, 37 white
    # bg: 40 black, 41 red, 44 blue, 45 purple
    # append >&2 to print to stderr
}


echo "*** Killing old stopped or running containers..."
container_name=tor
if docker ps -a --format '{{.Names}}' | grep -Eq "^${container_name}\$"; then
  docker compose -f tor/docker-compose.yml down
else
  echo "*** TOR container doesn't seem to be running, assuming stopped."
fi

container_name=vpn
if docker ps -a --format '{{.Names}}' | grep -Eq "^${container_name}\$"; then
  docker compose -f vpn/docker-compose.yml down
  echo "*** Waiting 5 seconds to make sure network detach before staring a new one..."
  waitWithCounter 5
else
  echo "*** VPN container doesn't seem to be running, assuming stopped."
fi

HOME_IP=$(curl -s https://checkip.amazonaws.com)
echo "*** Your home IP: $HOME_IP"
echo "*** starting VPN container"
docker compose -f vpn/docker-compose.yml up -d  
echo "*** Waiting 5 seconds to make sure connection established"
waitWithCounter 5
IP=$(docker exec vpn curl -s https://checkip.amazonaws.com)
echo "*** VPN obtained IP: $IP"

if [ "$HOME_IP" == "$IP" ]
then
    echoColor '31;1' "*** VPN did not connect or we checked too early. Please try again or verify VPN auth TOKEN in vpn/docker-compose.yml" >&2
    echoColor '33;1' "*** Stopping VPN"
    docker compose -f vpn/docker-compose.yml down
    exit 1
else
    docker compose -f tor/docker-compose.yml up -d
    localIP=$(ip route get 1 | awk '{print $(NF-2);exit}')
    echo "Tor should be available via 127.0.0.1:9050 or from any other machine via $localIP" 
fi 

sleep 5 # wait before exit to let user read the output if executed directly 

