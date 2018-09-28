#! /bin/bash

# Define variables
function defineVariables() {
  PROJECT_NAME=$1
  SLAVE_MIN=$2
  JENKINS_USER='admin'
  JENKINS_PASSWORD=$(/home/ec2-user/printJenkinsPassword.sh)
  JENKINS_IP=$(curl ipinfo.io/ip)
  SLAVE_MAX_INDEX=$SLAVE_MIN+1
}

# Configure ECS CLI
function configureEcsCli() {
  sudo /usr/local/bin/ecs-cli configure --cluster $PROJECT_NAME-jenkins-slaves --region us-east-2 --default-launch-type EC2 --config-name $PROJECT_NAME-jenkins-slaves
}

# Create Jenkins slave configuration payload
function createJenkinsSlaveConfigPayload() {
  mkdir /home/ec2-user/slaves/slave$SLAVE_INDEX
  touch /home/ec2-user/slaves/slave$SLAVE_INDEX/slave-config.xml
	cat <<- EOF > /home/ec2-user/slaves/slave$SLAVE_INDEX/slave-config.xml
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
	EOF
}

# Create a new node/slave in Jenkins
function createSlaveInJenkins() {
  java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:$(/home/ec2-user/printJenkinsPassword.sh) create-node < /home/ec2-user/slaves/slave$SLAVE_INDEX/slave-config.xml
  sleep 10
  SLAVE_SECRET_KEY=$(curl -H "$(curl -s 'http://'$JENKINS_USER':'$JENKINS_PASSWORD'@http://localhost:8080/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb')" -L -s -u $JENKINS_USER:$JENKINS_PASSWORD http://localhost:8080/computer/slave$SLAVE_INDEX/slave-agent.jnlp | grep -Po '[A-Fa-f0-9]{64}')
}

# Create a Docker Compose file specific to a slave for use with the ECS CLI
function createDockerComposeFile() {
  touch /home/ec2-user/slaves/slave$SLAVE_INDEX/docker-compose.yml
	cat <<- EOF > /home/ec2-user/slaves/slave$SLAVE_INDEX/docker-compose.yml
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
	EOF
}

# Create a parameters file for the compute resources given to a specific slave for use with the ECS CLI
function createEcsParamsFile() {
  touch /home/ec2-user/slaves/slave$SLAVE_INDEX/ecs-params.yml
	cat <<- EOF > /home/ec2-user/slaves/slave$SLAVE_INDEX/ecs-params.yml
		version: 1
		task_definition:
		  ecs_network_mode: bridge
		  services:
		    slave:
		      cpu_shares: 1024
		      mem_limit: 2065000000
	EOF
}

# Launch a new instance in AWS using the Docker Compose file and ECS CLI
function launchSlaveInEcs() {
  pushd /home/ec2-user/slaves/slave$SLAVE_INDEX
  sudo /usr/local/bin/ecs-cli compose up --region us-east-2 --cluster rispd-jenkins-slaves 2>deploy.log
  popd
}

# For each slave that is required at the minimum, create the Jenkins slave config payload, create the slave, create the Docker Compose files to launch the slave in ECS, and deploy the slave in ECS
function createSlaves() {
  for (( SLAVE_INDEX=1; SLAVE_INDEX<SLAVE_MAX_INDEX; SLAVE_INDEX++ )) do
    createJenkinsSlaveConfigPayload
    createSlaveInJenkins
    createDockerComposeFile
    createEcsParamsFile
    launchSlaveInEcs
  done
}

# Change ownership of all files in the ec2-user's home directory to be owned by ec2-user
function changeOwnershipOfFiles() {
  sudo chown ec2-user:ec2-user -R /home/ec2-user/slaves
}

defineVariables "$@"
configureEcsCli
createSlaves
changeOwnershipOfFiles
