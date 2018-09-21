#! /bin/bash

PROJECT_NAME=rispd
SLAVE_MIN=2
JENKINS_USER='admin'
JENKINS_PASSWORD=$(/home/ec2-user/printJenkinsPassword.sh)
JENKINS_IP=$(curl ipinfo.io/ip)

# 1. Create slaves on the Jenkins master
# 2. Create folders for slaves
mkdir /home/ec2-user/slaves
for (( SLAVE_INDEX=0; SLAVE_INDEX<SLAVE_MIN; SLAVE_INDEX++ )) do
SLAVE_SECRET_KEY=$(curl -H "$(curl -s 'http://'$JENKINS_USER':'$JENKINS_PASSWORD'@http://localhost:8080/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb')" -L -s -u $JENKINS_USER:$JENKINS_PASSWORD http://localhost:8080/computer/slave$SLAVE_INDEX/slave-agent.jnlp | grep -Po '[A-Fa-f0-9]{64}')
mkdir /home/ec2-user/slaves/slave$SLAVE_INDEX
touch /home/ec2-user/slaves/slave$SLAVE_INDEX/docker-compose.yml
sudo ed -s /home/ec2-user/slaves/slave$SLAVE_INDEX/docker-compose.yml >> /dev/null <<EOF
i
version: "3"
services:
  slave:
    image: 118104210923.dkr.ecr.us-east-2.amazonaws.com/jenkins-slave:$PROJECT_NAME
    environment:
      JENKINS_IP: $JENKINS_IP
      SECRET_KEY: $SLAVE_SECRET_KEY
      SLAVE_NUMBER: $SLAVE_INDEX
    logging:
      driver: awslogs
      options:
        awslogs-group: slave
        awslogs-region: us-east-2
        awslogs-stream-prefix: slave_
.
w
EOF
touch /home/ec2-user/slaves/slave$SLAVE_INDEX/ecs-params.yml
sudo ed -s /home/ec2-user/slaves/slave$SLAVE_INDEX/ecs-params.yml >> /dev/null <<EOF
i
version: 1
task_definition:
  ecs_network_mode: bridge
  services:
    slave:
      cpu_shares: 2048
      mem_limit: 4130000000
.
w
EOF
done

# 3. Run boilerplate to set up ECS CLI
# 4. Login to ECR
# 5. Create docker-compose.yml and ecs-params.yml
# 6. Launch tasks using compose-up (one for each instance)
