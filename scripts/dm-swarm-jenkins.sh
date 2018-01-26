#!/bin/bash

cd cloud-provisioning
scripts/dm-swarm.sh
mkdir -p docker/jenkins

eval $(docker-machine env swarm-1)

docker service create --name jenkins \
-p 8082:8080 \
-p 50000:50000 \
-e JENKINS_OPTS="--prefix=/jenkins" \
--mount "type=bind,source=$PWD/docker/jenkins,target=/var/jenkins_home" \
--reserve-memory 300m \
jenkins/jenkins:2.103-alpine # jenkins:2.60.3-alpine

scripts/dm-test-swarm-2.sh
eval $(docker-machine env swarm-test-1)

docker-machine ssh swarm-test-1
sudo mkdir /workspace && sudo chmod 777 /workspace && exit


export USER=admin
export PASSWORD=admin
docker service create --name jenkins-agent \
-e COMMAND_OPTIONS="-master http://$(docker-machine ip swarm-1):8082/jenkins
-username $USER -password $PASSWORD -labels 'docker' -executors 5" \
--mode global \
--constraint 'node.labels.env == jenkins-agent' \
--mount \
"type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock" \
--mount \
"type=bind,source=/hosthome/gide0n/.docker/machine/machines,target=/machines" \
--mount "type=bind,source=/workspace,target=/workspace" \
vfarcic/jenkins-swarm-agent