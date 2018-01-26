#!/bin/bash

curl -o /tmp/jenkins.yml https://raw.githubusercontent.com/9ide0n/docker-flow-stacks/master/jenkins/jenkins.yml
curl -o /tmp/jenkins-local.yml https://raw.githubusercontent.com/9ide0n/docker-flow-stacks/master/jenkins/jenkins-local.yml

eval $(docker-machine env swarm-1)

export UI_PORT=8082 
docker-compose -f /tmp/jenkins.yml -f /tmp/jenkins-local.yml config | tee /tmp/jenkins-stack.yml
docker stack deploy -c /tmp/jenkins-stack.yml jenkins 
# docker stack deploy --compose-file=<(docker-compose -f /tmp/jenkins.yml -f /tmp/jenkins-local.yml config) jenkins

curl -o /tmp/jenkins-swarm-agent.yml https://raw.githubusercontent.com/9ide0n/docker-flow-stacks/master/jenkins/jenkins-swarm-agent.yml
curl -o /tmp/jenkins-swarm-agent-local.yml https://raw.githubusercontent.com/9ide0n/docker-flow-stacks/master/jenkins/jenkins-swarm-agent-local.yml

docker-machine ssh swarm-test-1 "sudo mkdir -p /workspace && sudo chmod 777 /workspace" 

eval $(docker-machine env swarm-test-1)
JENKINS_IP=$(docker-machine ip swarm-1):$UI_PORT docker-compose -f /tmp/jenkins-swarm-agent.yml -f /tmp/jenkins-swarm-agent-local.yml config | tee /tmp/jenkins-agent-stack.yml 
docker stack deploy -c /tmp/jenkins-agent-stack.yml jenkins-agent
# docker stack deploy --compose-file=<(JENKINS_IP=$(docker-machine ip swarm-1):$UI_PORT docker-compose -f /tmp/jenkins-swarm-agent.yml -f /tmp/jenkins-swarm-agent-local.yml config)  jenkins-agent
    
rm /tmp/jenkins*.yml
