#!/bin/bash

curl -o /tmp/docker-flow-proxy.yml https://raw.githubusercontent.com/9ide0n/docker-flow-stacks/master/proxy/docker-flow-proxy.yml

eval $(docker-machine env swarm-1)
docker network create --driver overlay proxy
docker stack deploy -c /tmp/docker-flow-proxy.yml proxy 

rm /tmp/docker-flow-proxy.yml
