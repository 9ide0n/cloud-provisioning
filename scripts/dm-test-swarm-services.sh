#!/usr/bin/env bash

eval $(docker-machine env swarm-test-1)

docker network create --driver overlay proxy

docker network create --driver overlay go-demo

echo "registry:"
docker service create --name registry \
    -p 5000:5000 \
    --reserve-memory 100m \
    --replicas 2 \
    --constraint 'node.labels.env == prod-like' \
    --mount "type=bind,source=$PWD,target=/var/lib/registry" \
    registry:2.5.0


echo "swarm-listener:"
docker service create --name swarm-listener \
    --network proxy \
    --replicas 2 \
    --mount "type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock" \
    -e DF_NOTIFY_CREATE_SERVICE_URL=http://proxy:8080/v1/docker-flow-proxy/reconfigure \
    -e DF_NOTIFY_REMOVE_SERVICE_URL=http://proxy:8080/v1/docker-flow-proxy/remove \
    --constraint 'node.role==manager' \
    --constraint 'node.labels.env == prod-like' \
    vfarcic/docker-flow-swarm-listener:18.01.06-29


echo "proxy:"
docker service create --name proxy \
    -p 80:80 \
    -p 443:443 \
    --network proxy \
    --replicas 2 \
    -e LISTENER_ADDRESS=swarm-listener \
    --constraint 'node.labels.env == prod-like' \
    vfarcic/docker-flow-proxy:18.01.18-98

echo "go-demo-db:"
docker service create --name go-demo-db \
    --network go-demo \
    --constraint 'node.labels.env == prod-like' \
    mongo:3.2.10

echo "go-demo v1.6:"
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

echo -e "To rolling update use service version >=1.7 like so:\ndocker service update \
--image=localhost:5000/go-demo:1.7 \
go-demo"

echo ""
echo ">> The services are up and running inside the swarm test cluster"
