#!/bin/bash

cd "${0%/*}" #go to dir where the script is located in case exec form a diffrent location

docker compose -f nordlynx-tor/docker-compose.yml down

echo "*** Done!"

sleep 5 # wait before exit to let user read the output if executed directly 
