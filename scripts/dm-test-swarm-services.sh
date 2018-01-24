#!/usr/bin/env bash

eval $(docker-machine env swarm-test-1)

docker network create --driver overlay proxy

docker network create --driver overlay go-demo


echo "swarm-listener:"
docker service create --name swarm-listener \
    --network proxy \
    --replicas 2 \
    --mount "type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock" \
    -e DF_NOTIFY_CREATE_SERVICE_URL=http://proxy:8080/v1/docker-flow-proxy/reconfigure \
    -e DF_NOTIFY_REMOVE_SERVICE_URL=http://proxy:8080/v1/docker-flow-proxy/remove \
    --constraint 'node.role==manager' \
    --constraint 'node.labels.env == prod-like' \
    vfarcic/docker-flow-swarm-listener


echo "proxy:"
docker service create --name proxy \
    -p 80:80 \
    -p 443:443 \
    --network proxy \
    --replicas 2 \
    -e LISTENER_ADDRESS=swarm-listener \
    --constraint 'node.labels.env == prod-like' \
    vfarcic/docker-flow-proxy

echo "go-demo-db:"
docker service create --name go-demo-db \
    --network go-demo \
    --constraint 'node.labels.env == prod-like' \
    mongo:3.2.10

echo "go-demo:"
docker service create --name go-demo \
    -e DB=go-demo-db \
    --network go-demo \
    --network proxy \
    --replicas 2 \
    --label com.df.notify=true \
    --label com.df.servicePath=/demo \
    --label com.df.port=8080 \
    --constraint 'node.labels.env == prod-like' \
    --update-delay 5s \
    vfarcic/go-demo:1.6

echo ""
echo ">> The services are up and running inside the swarm test cluster"
