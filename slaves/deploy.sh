#! /bin/bash

# Set variables
PROJECT_NAME=$1
AWS_ACCESS_KEY=$2
AWS_SECRET_KEY=$3
SLAVE_MIN=$4

# Create key pair
aws --region us-east-2 ec2 create-key-pair --key-name $PROJECT_NAME-jenkins-slaves --query 'KeyMaterial' --output text > ~/Desktop/$PROJECT_NAME-jenkins-slaves.pem
KEY_PAIR=$(cat ~/Desktop/$PROJECT_NAME-jenkins-slaves.pem)
if [ ${#KEY_PAIR} == 0 ]; then
  echo -e ""
  echo -e "${COLOR_RED}ERROR: PEM file was unable to be created. Do you have permissions on your AWS account to create key pairs?"
  echo -e "${COLOR_NONE}"
  exit 2
else
  chmod 400 ~/Desktop/$PROJECT_NAME-jenkins-slaves.pem
fi

# Configure ECS cluster
ecs-cli configure --cluster $PROJECT_NAME-jenkins-slaves --region us-east-2 --default-launch-type EC2 --config-name $PROJECT_NAME-jenkins-slaves

# Configure profile
ecs-cli configure profile --access-key $AWS_ACCESS_KEY --secret-key $AWS_SECRET_KEY --profile-name $PROJECT_NAME

# Create ECS cluster
ecs-cli up --keypair $PROJECT_NAME-jenkins-slaves --capability-iam --size $SLAVE_MIN --instance-type t2.small --cluster-config $PROJECT_NAME-jenkins-slaves
