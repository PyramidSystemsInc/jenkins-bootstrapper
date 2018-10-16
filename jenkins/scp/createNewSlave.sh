#! /bin/bash

JENKINS_USER='admin'
JENKINS_IP=$(curl ipinfo.io/ip)

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
  java -jar /home/ec2-user/jenkins-cli.jar -s http://localhost:8080 -auth admin:$(/home/ec2-user/printJenkinsPassword.sh) create-node < /home/ec2-user/slaves/slave$SLAVE_INDEX/slave-config.xml
  sleep 10
  SLAVE_SECRET_KEY=$(curl -H "$(curl -s 'http://'$JENKINS_USER':'$JENKINS_PASSWORD'@http://localhost:8080/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb')" -L -s -u $JENKINS_USER:$JENKINS_PASSWORD http://localhost:8080/computer/slave$SLAVE_INDEX/slave-agent.jnlp | grep -Po '[A-Fa-f0-9]{64}')
}

# Launch a new instance in AWS using the Docker Compose file and ECS CLI
function launchSlaveInEcs() {
  pushd /home/ec2-user/aws-scripts
  ./launchEcsTask.sh --cluster $PROJECT_NAME-jenkins-slaves --task slave$SLAVE_INDEX --container "docker run --name slave$SLAVE_INDEX -e JENKINS_IP=$JENKINS_IP -e SECRET_KEY=$SLAVE_SECRET_KEY -e SLAVE_NUMBER=$SLAVE_INDEX --cpu 1 --memory 2 ecr/jenkins-slave:$PROJECT_NAME"
  popd
}

# Pull project name from a safe location
PROJECT_NAME=$(sed -e 's/-jenkins//g' <<< $(cat /home/ec2-user/.ssh/authorized_keys | grep -Po '[[:space:]][a-zA-Z]*\-jenkins$'))

# Configure the ECS CLI to use the correct cluster and region
sudo /usr/local/bin/ecs-cli configure --cluster $PROJECT_NAME-jenkins-slaves --region us-east-2 --default-launch-type EC2 --config-name $PROJECT_NAME-jenkins-slaves

# Query how many slaves are currently in the cluster
CURRENT_SLAVE_COUNT=$(aws ecs describe-clusters --cluster $PROJECT_NAME-jenkins-slaves --region us-east-2 | jq '.clusters[0].registeredContainerInstancesCount')

# Scale up the cluster
DESIRED_SLAVE_COUNT=$(($CURRENT_SLAVE_COUNT + 1))
sudo /usr/local/bin/ecs-cli scale --cluster $PROJECT_NAME-jenkins-slaves --size $DESIRED_SLAVE_COUNT --region us-east-2 --capability-iam

# Set the Jenkins password variable
JENKINS_PASSWORD=$(/home/ec2-user/printJenkinsPassword.sh)

# Get a Jenkins "crumb" for authentication
JENKINS_CRUMB=$(curl -s "http://admin:"$JENKINS_PASSWORD"@localhost:8080/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)")

# Get all unique node numbers used in Jenkins
NODE_NUMBERS=()
NODES=$(jq -r '.computer' <<< $(curl -H $JENKINS_CRUMB -L -s -u admin:$JENKINS_PASSWORD localhost:8080/computer/api/json))
NODE_COUNT=$(echo $NODES | jq '. | length')
for (( NODE_INDEX=0; NODE_INDEX<NODE_COUNT; NODE_INDEX++ )) do
  NODE_NAME=$(sed -e 's/^"//g' -e 's/"$//g' <<< $(echo $NODES | jq '.['"$NODE_INDEX"'].displayName'))
  NODE_OFFLINE=$(sed -e 's/^"//g' -e 's/"$//g' <<< $(echo $NODES | jq '.['"$NODE_INDEX"'].offline'))
  if [ $NODE_NAME != "master" ] && [ $NODE_OFFLINE == "false" ]; then
    NODE_NUMBERS+=($(sed -e 's/slave//g' <<< $NODE_NAME))
  fi
done

# Find the first number that is not known by Jenkins
NUMBER_CANDIDATE=1
NUMBER_FOUND=false
while [ $NUMBER_FOUND == false ]; do
  NUMBER_FOUND=true
  for NODE_NUMBER in "${NODE_NUMBERS[@]}"; do
    if [ $NUMBER_CANDIDATE == $NODE_NUMBER ]; then
      NUMBER_FOUND=false
    fi
  done
  if [ $NUMBER_FOUND == false ]; then
    ((NUMBER_CANDIDATE++))
  else
    SLAVE_INDEX=$NUMBER_CANDIDATE
  fi
done

rm -Rf /home/ec2-user/slaves/slave$SLAVE_INDEX || true
createJenkinsSlaveConfigPayload
createSlaveInJenkins
# createDockerComposeFile
# createEcsParamsFile

# Wait until the registered container instances count of the cluster reaches the desired slave count
while : ; do
  CURRENT_SLAVE_COUNT=$(aws ecs describe-clusters --cluster "$PROJECT_NAME"-jenkins-slaves --region us-east-2 | jq '.clusters[0].registeredContainerInstancesCount')
  [[ $CURRENT_SLAVE_COUNT -eq $DESIRED_SLAVE_COUNT ]] || break
  sleep 2
done
# TODO: Check for instance ids of initializing instances and wait until they are all no longer in "initializing" state
sleep 30

launchSlaveInEcs

sleep 75
rm /home/ec2-user/slaves/.slave-creation-lock
