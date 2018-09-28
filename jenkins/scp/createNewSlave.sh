#! /bin/bash

# Pull project name from a safe location
#PROJECT_NAME=$(sed -e 's/-jenkins//g' <<< $(cat /home/ec2-user/.ssh/authorized_keys | grep -Po '[[:space:]][a-zA-Z]*\-jenkins$'))

# Configure the ECS CLI to use the correct cluster and region
#ecs-cli configure --cluster $PROJECT_NAME-jenkins-slaves --region us-east-2 --default-launch-type EC2 --config-name $PROJECT_NAME-jenkins-slaves

# Query how many slaves are currently in the cluster
#CURRENT_SLAVE_COUNT=$(aws ecs describe-clusters --cluster $PROJECT_NAME-jenkins-slaves --region us-east-2 | jq '.clusters[0].registeredContainerInstancesCount')

# Scale up the cluster
#ecs-cli scale --cluster $PROJECT_NAME-jenkins-slaves --size $(($CURRENT_SLAVE_COUNT + 1)) --region us-east-2 --capability-iam

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
echo ${NODE_NUMBERS[*]}
