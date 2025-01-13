#!/bin/bash

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
docker compose -f nordlynx-tor/docker-compose.yml down

HOME_IP=$(curl -s https://checkip.amazonaws.com)
echo "*** Your home IP: $HOME_IP"
echo "*** starting containers"
docker compose -f nordlynx-tor/docker-compose.yml up -d  
waitSeconds=5
echo "*** Waiting $waitSeconds seconds to make sure connection established"
waitWithCounter $waitSeconds
IP=$(docker exec nordlynx curl -s https://checkip.amazonaws.com)
echo "*** VPN obtained IP: $IP"

if [ "$HOME_IP" == "$IP" ]
then
    echoColor '31;1' "*** VPN did not connect or we checked too early. Please try again or verify VPN auth PRIVATE_KEY in nordlynx-tor/docker-compose.yml" >&2
    echoColor '33;1' "*** Stopping VPN and TOR"
    docker compose -f nordlynx-tor/docker-compose.yml down
    exit 1
else
    localIP=$(ip route get 1 | awk '{print $(NF-2);exit}')
    echo "Tor should be available via 127.0.0.1:9050 or from any other machine via $localIP" 
fi 

sleep 5 # wait before exit to let user read the output if executed directly 

