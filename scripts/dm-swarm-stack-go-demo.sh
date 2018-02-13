#!/bin/bash

curl -o /tmp/go-demo-stack.yml https://raw.githubusercontent.com/vfarcic/go-demo/master/docker-compose-stack.yml

eval $(docker-machine env swarm-1)
docker network create --driver overlay proxy
docker stack deploy -c /tmp/go-demo-stack.yml go-demo 

rm /tmp/go-demo-stack.yml
