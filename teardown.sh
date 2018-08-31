#1 /bin/bash

# Define color palette
COLOR_RED='\033[0;31m'
COLOR_WHITE='\033[0;37m'
COLOR_NONE='\033[0m'

# Ensure a project name is provided
if [ -z "$1" ]; then
  echo -e "${COLOR_RED}ERROR: Project name must be provided. Please re-run as follows:${COLOR_NONE}"
  echo -e "${COLOR_WHITE}    ./deploy.sh <PROJECT_NAME>"
  echo -e "    -OR-"
  echo -e "    ./deploy.sh <PROJECT_NAME> <AWS_ACCESS_KEY> <AWS_SECRET_KEY>"
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

# Delete key pair
sudo rm ~/Desktop/$PROJECT_NAME-jenkins.pem
aws --region us-east-2 ec2 delete-key-pair --key-name $PROJECT_NAME-jenkins

# Terminate EC2 instance
pulumi stack select $PROJECT_NAME-jenkins
pulumi config set cloud:provider aws
pulumi config set aws:region us-east-2
pulumi config set cloud-aws:useFargate true
pulumi destroy -y

# Destroy Selenium ECS cluster / CloudFormation stack
cd selenium
./teardown.sh
cd ..

# Cleanup
rm Pulumi.$PROJECT_NAME-jenkins.yaml
