#! /bin/bash

PROJECT_NAME=$1
SLAVE_MIN=$2
JENKINS_USER='admin'
JENKINS_PASSWORD=$(/home/ec2-user/printJenkinsPassword.sh)
JENKINS_IP=$(curl ipinfo.io/ip)
SLAVE_MAX_INDEX=$SLAVE_MIN+1

sudo /usr/local/bin/ecs-cli configure --cluster $PROJECT_NAME-jenkins-slaves --region us-east-2 --default-launch-type EC2 --config-name $PROJECT_NAME-jenkins-slaves
for (( SLAVE_INDEX=1; SLAVE_INDEX<SLAVE_MAX_INDEX; SLAVE_INDEX++ )) do
mkdir /home/ec2-user/slaves/slave$SLAVE_INDEX
touch /home/ec2-user/slaves/slave$SLAVE_INDEX/slave-config.xml
sudo ed -s /home/ec2-user/slaves/slave$SLAVE_INDEX/slave-config.xml >> /dev/null <<EOF
i
<?xml version="1.1" encoding="UTF-8"?>
<slave>
  <name>slave$SLAVE_INDEX</name>
  <description></description>
  <remoteFS>/home/ec2-user</remoteFS>
  <numExecutors>1</numExecutors>
  <mode>NORMAL</mode>
  <retentionStrategy class="hudson.slaves.RetentionStrategy\$Always"/>
  <launcher class="hudson.slaves.JNLPLauncher">
    <workDirSettings>
      <disabled>false</disabled>
      <internalDir>remoting</internalDir>
      <failIfWorkDirIsMissing>false</failIfWorkDirIsMissing>
    </workDirSettings>
  </launcher>
  <label></label>
  <nodeProperties/>
</slave>
.
w
EOF
java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:$(/home/ec2-user/printJenkinsPassword.sh) create-node < /home/ec2-user/slaves/slave$SLAVE_INDEX/slave-config.xml
sleep 10
SLAVE_SECRET_KEY=$(curl -H "$(curl -s 'http://'$JENKINS_USER':'$JENKINS_PASSWORD'@http://localhost:8080/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb')" -L -s -u $JENKINS_USER:$JENKINS_PASSWORD http://localhost:8080/computer/slave$SLAVE_INDEX/slave-agent.jnlp | grep -Po '[A-Fa-f0-9]{64}')
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
      cpu_shares: 1024
      mem_limit: 2065000000
.
w
EOF
pushd /home/ec2-user/slaves/slave$SLAVE_INDEX
env HOME=$(pwd)
sudo /usr/local/bin/ecs-cli compose up --region us-east-2 --cluster rispd-jenkins-slaves 2>deploy.log
popd
done
sudo chown ec2-user:ec2-user -R /home/ec2-user/slaves
