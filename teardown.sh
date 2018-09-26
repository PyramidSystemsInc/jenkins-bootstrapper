#1 /bin/bash

# Define color palette
COLOR_RED='\033[0;31m'
COLOR_WHITE='\033[0;37m'
COLOR_NONE='\033[0m'

# Ensure a project name is provided
if [ -z "$1" ]; then
  echo -e "${COLOR_RED}ERROR: Project name must be provided. Please re-run as follows:${COLOR_NONE}"
  echo -e "${COLOR_WHITE}    ./teardown.sh <PROJECT_NAME>"
  echo -e "    -OR-"
  echo -e "    ./teardown.sh <PROJECT_NAME> <AWS_ACCESS_KEY> <AWS_SECRET_KEY>"
  echo -e "${COLOR_NONE}"
  exit 2
else
  PROJECT_NAME=$1
fi

# Attempt to load AWS credentials if not provided
if [ -z "$3" ]; then
  echo -e "${COLOR_WHITE}NOTICE: Using existing AWS credentials (found at ~/.aws/credentials)${COLOR_NONE}"
  AWS_CREDENTIALS=($(cat ~/.aws/credentials))
  AWS_ACCESS_KEY=${AWS_CREDENTIALS[3]}
  AWS_SECRET_KEY=${AWS_CREDENTIALS[6]}
  if [ ${#AWS_ACCESS_KEY} != 20 ] || [ ${#AWS_SECRET_KEY} != 40 ]; then
    echo -e "${COLOR_RED}ERROR: Could not find a valid set of credentials at ~/.aws/credentials"
    echo -e "Please re-run with AWS credentials specified as follows:${COLOR_NONE}"
    echo -e "${COLOR_WHITE}    ./teardown.sh <PROJECT_NAME> <AWS_ACCESS_KEY> <AWS_SECRET_KEY>"
    echo
    echo -e "${COLOR_RED}For Example:${COLOR_NONE}"
    echo -e "    ./teardown.sh rispd aeZ87sVkkdjfs askdf832ls97smvms8o"
    echo -e "${COLOR_NONE}"
    exit 2
  fi
fi

# Destroy Selenium ECS cluster / CloudFormation stack
cd selenium
rm -f logs/teardown.log
./teardown.sh $PROJECT_NAME 2>logs/teardown.log &
cd ..

# Destroy Jenkins Slaves ECS cluster / CloudFormation stack
cd slaves
rm -f logs/teardown.log
./teardown.sh $PROJECT_NAME 2>logs/teardown.log &
cd ..

# Create JENKINS_ID variable
JENKINS_ID=$PROJECT_NAME-jenkins

# Delete key pair
sudo rm ~/Desktop/$JENKINS_ID.pem
aws --region us-east-2 ec2 delete-key-pair --key-name $JENKINS_ID

# Terminate any running EC2 instances and any security groups named $JENKINS_ID
INSTANCE_FOUND='false'
while [ "$INSTANCE_FOUND" == "false" ]; do
  INSTANCE_COUNT=$(aws ec2 describe-instances --filter Name=instance-state-code,Values=16 | jq '.Reservations[0].Instances | length')
  for (( INSTANCE_INDEX=0; INSTANCE_INDEX<INSTANCE_COUNT; INSTANCE_INDEX++ )) do
    if [ $(aws ec2 describe-instances --filter Name=instance-state-code,Values=16 | jq '.Reservations[0].Instances['"$INSTANCE_INDEX"'].KeyName') == "\"$JENKINS_ID\"" ]; then
      INSTANCE_FOUND='true'
      INSTANCE_ID=$(sed -e 's/^"//' -e 's/"$//' <<< $(aws ec2 describe-instances --filter Name=instance-state-code,Values=16 | jq '.Reservations[0].Instances['"$INSTANCE_INDEX"'].InstanceId'))
      aws ec2 terminate-instances --instance-ids $INSTANCE_ID
    fi
  done
done

# Wait until the instance and volume are terminated to delete the security group
INSTANCE_SHUTTING_DOWN=true
while [ "$INSTANCE_SHUTTING_DOWN" == true ]; do
  if [ "$(aws ec2 describe-instances --instance-id $INSTANCE_ID --filter Name=instance-state-code,Values=48 | jq '.Reservations[0].Instances[0]')" != "null" ]; then
    INSTANCE_SHUTTING_DOWN=false
    aws ec2 delete-security-group --group-name $JENKINS_ID
  fi
done
