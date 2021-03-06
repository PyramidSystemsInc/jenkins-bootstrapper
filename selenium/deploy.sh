#! /bin/bash

# Set variables
PROJECT_NAME=$1
AWS_ACCESS_KEY=$2
AWS_SECRET_KEY=$3

# Create key pair
aws --region us-east-2 ec2 create-key-pair --key-name $PROJECT_NAME-selenium --query 'KeyMaterial' --output text > ~/Desktop/$PROJECT_NAME-selenium.pem
KEY_PAIR=$(cat ~/Desktop/$PROJECT_NAME-selenium.pem)
if [ ${#KEY_PAIR} == 0 ]; then
  echo -e ""
  echo -e "${COLOR_RED}ERROR: PEM file was unable to be created. Do you have permissions on your AWS account to create key pairs?"
  echo -e "${COLOR_NONE}"
  exit 2
else
  chmod 400 ~/Desktop/$PROJECT_NAME-selenium.pem
fi

# Configure ECS cluster
ecs-cli configure --cluster $PROJECT_NAME-selenium --region us-east-2 --default-launch-type EC2 --config-name $PROJECT_NAME-selenium

# Configure profile
ecs-cli configure profile --access-key $AWS_ACCESS_KEY --secret-key $AWS_SECRET_KEY --profile-name $PROJECT_NAME

# Create ECS cluster
ecs-cli up --keypair $PROJECT_NAME-selenium --capability-iam --size 1 --instance-type t2.medium --cluster-config $PROJECT_NAME-selenium

# Ensure EC2 container instance is up (ECS CLI executes the next command before the instance initializes and a 400 is returned)
sleep 45

# Create ECS tasks
ecs-cli compose up --create-log-groups --cluster-config $PROJECT_NAME-selenium
