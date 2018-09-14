#! /bin/bash

# Define color palette
COLOR_RED='\033[0;31m'
COLOR_WHITE='\033[0;37m'
COLOR_NONE='\033[0m'

# Ensure a Jenkins ID is provided
if [ -z "$1" ]; then
  echo -e "${COLOR_RED}ERROR: Project name must be provided. Please re-run as follows:${COLOR_NONE}"
  echo -e "${COLOR_WHITE}    ./createJenkinsInstance.sh <JENKINS_ID> <AWS_IAM_ROLE_FOR_NEW_JENKINS_INSTANCE>"
  echo -e "${COLOR_NONE}"
  exit 2
else
  JENKINS_ID=$1-jenkins
fi

# Ensure an IAM role is provided
if [ -z "$2" ]; then
  echo -e "${COLOR_RED}ERROR: IAM role must be provided. Please re-run as follows:${COLOR_NONE}"
  echo -e "${COLOR_WHITE}    ./createJenkinsInstance.sh <JENKINS_ID> <AWS_IAM_ROLE_FOR_NEW_JENKINS_INSTANCE>"
  echo -e "${COLOR_NONE}"
  exit 2
else
  AWS_IAM_ROLE=$2
fi

# Create Jenkins security group
SECURITY_GROUP_ID=$(sed -e 's/^"//' -e 's/"$//' <<< $(echo $(aws ec2 create-security-group --group-name $JENKINS_ID --description "Created by jenkins-bootstrapper") | jq '.GroupId'))
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 443 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 8080 --cidr 0.0.0.0/0

# Create Jenkins key pair
sudo rm ~/Desktop/$JENKINS_ID.pem
aws --region us-east-2 ec2 create-key-pair --key-name $JENKINS_ID --query 'KeyMaterial' --output text > ~/Desktop/$JENKINS_ID.pem
KEY_PAIR=$(cat ~/Desktop/$JENKINS_ID.pem)
if [ ${#KEY_PAIR} == 0 ]; then
  echo -e ""
  echo -e "${COLOR_RED}ERROR: PEM file was unable to be created. Do you have permissions on your AWS account to create key pairs?"
  echo -e "${COLOR_NONE}"
  exit 2
else
  chmod 400 ~/Desktop/$JENKINS_ID.pem
fi

# Create Jenkins EC2 instance
INSTANCE_ID=$(sed -e 's/^"//' -e 's/"$//' <<< $(echo $(aws ec2 run-instances --image-id ami-40142d25 --count 1 --instance-type t3.medium --key-name $JENKINS_ID --security-group-ids $SECURITY_GROUP_ID --iam-instance-profile Name="$AWS_IAM_ROLE" --block-device-mappings "[{\"DeviceName\":\"/dev/xvda\",\"Ebs\":{\"VolumeSize\":16}}]" --user-data file://jenkins/userData.sh) | jq '.Instances[0].InstanceId'))

# Add a name to the EC2 instance
aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=$JENKINS_ID

# Clean up user data script
# sudo rm jenkins/userData.sh
