#! /bin/bash

# Define color palette
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[0;33m'
COLOR_WHITE='\033[0;37m'
COLOR_NONE='\033[0m'

# Ensure a project name is provided
if [ -z "$1" ]; then
  echo -e "${COLOR_RED}ERROR: Project name must be provided. Please re-run as follows:${COLOR_NONE}"
  echo -e "${COLOR_WHITE}    ./deploy.sh <PROJECT_NAME> <EXISTING_AWS_HOSTED_ZONE_NAME>"
  echo -e "    -OR-"
  echo -e "    ./deploy.sh <PROJECT_NAME> <EXISTING_AWS_HOSTED_ZONE_NAME> <AWS_ACCESS_KEY> <AWS_SECRET_KEY>"
  echo -e "${COLOR_NONE}"
  exit 2
else
  PROJECT_NAME=$1
fi

# Ensure a hosted zone name is provided
if [ -z "$2" ]; then
  echo -e "${COLOR_RED}ERROR: A hosted zone name must be provided. Please re-run as follows:${COLOR_NONE}"
  echo -e "${COLOR_WHITE}    ./deploy.sh <PROJECT_NAME> <EXISTING_AWS_HOSTED_ZONE_NAME>"
  echo -e "    -OR-"
  echo -e "    ./deploy.sh <PROJECT_NAME> <EXISTING_AWS_HOSTED_ZONE_NAME> <AWS_ACCESS_KEY> <AWS_SECRET_KEY>"
  echo -e "${COLOR_NONE}"
  exit 2
else
  HOSTED_ZONE_NAME=$2
fi

# Attempt to load AWS credentials if not provided
# Otherwise, create or overwrite AWS credentials with the provided credentials
if [ -z "$4" ]; then
  echo -e "${COLOR_WHITE}NOTICE: Using existing AWS credentials (found at ~/.aws/credentials)${COLOR_NONE}"
  AWS_CREDENTIALS=($(cat ~/.aws/credentials))
  AWS_ACCESS_KEY=${AWS_CREDENTIALS[3]}
  AWS_SECRET_KEY=${AWS_CREDENTIALS[6]}
  if [ ${#AWS_ACCESS_KEY} != 20 ] || [ ${#AWS_SECRET_KEY} != 40 ]; then
    echo -e "${COLOR_RED}ERROR: Could not find a valid set of credentials at ~/.aws/credentials"
    echo -e "Please re-run with AWS credentials specified as follows:${COLOR_NONE}"
    echo -e "${COLOR_WHITE}    ./deploy.sh <PROJECT_NAME> <EXISTING_AWS_HOSTED_ZONE_NAME> <AWS_ACCESS_KEY> <AWS_SECRET_KEY>"
    echo
    echo -e "${COLOR_RED}For Example:${COLOR_NONE}"
    echo -e "    ./deploy.sh rispd rispd.pyramidchallenges.com. aeZ87sVkkdjfs askdf832ls97smvms8o"
    echo -e "${COLOR_NONE}"
    exit 2
  fi
else
  AWS_ACCESS_KEY=$3
  AWS_SECRET_KEY=$4
  if [ ! -f ~/.aws/credentials ]; then
    mkdir ~/.aws | true
    touch ~/.aws/credentials
    echo "[default]" | tee --append ~/.aws/credentials
    echo "aws_access_key_id = $AWS_ACCESS_KEY" | tee --append ~/.aws/credentials
    echo "aws_secret_access_key = $AWS_SECRET_KEY" | tee --append ~/.aws/credentials
  else
    sed -i 's/^aws_access_key_id.*/aws_access_key_id = '"$AWS_ACCESS_KEY"'/g' ~/.aws/credentials
    sed -i 's/^aws_secret_access_key.*/aws_secret_access_key = '"$AWS_SECRET_KEY"'/g' ~/.aws/credentials
  fi
fi

# Create Jenkins EC2 Instance
./jenkins/userDataGenerator.sh $PROJECT_NAME $HOSTED_ZONE_NAME $AWS_ACCESS_KEY $AWS_SECRET_KEY
./jenkins/createInstance.sh $PROJECT_NAME

# Start Selenium Grid
cd selenium
rm -f logs/clusterCreate.log logs/taskCreate.log
./deploy.sh $PROJECT_NAME >logs/clusterCreate.log 2>logs/taskCreate.log &
cd ..

# Create JENKINS_ID variable
# JENKINS_ID=$PROJECT_NAME-jenkins

# Print notices and warnings
# echo -e "${COLOR_WHITE}NOTICE: Logging into Jenkins EC2 instance with the command:"
# echo -e "    ssh -i ~/Desktop/$JENKINS_ID.pem ec2-user@$EC2_IP"
# echo -e "${COLOR_NONE}"
# echo -e "${COLOR_YELLOW}WARNING: The instance is still being configured so don't freak out if your stuff isn't there yet"
# echo -e "         You can monitor its progress by running in the instance:"
# echo -e "${COLOR_WHITE}    tail -f installProgress"
# echo -e "${COLOR_NONE}"
# echo -e "${COLOR_WHITE}NOTICE: Once the instance is done being configured, you can reach Jenkins at the following address in your browser:"
# echo -e "    $EC2_IP:8080"
# echo -e "${COLOR_NONE}"
# echo -e "${COLOR_WHITE}NOTICE: This is the webhook URL that must be pasted in to the Payload URL field on GitHub:"
# echo -e "    http://$EC2_IP:8080/github-webhook/"
# echo -e "${COLOR_NONE}"
# echo -e "${COLOR_WHITE}NOTICE: If navigating to the Jenkins web GUI, enter the username \"admin\""
# echo -e "        The password can be found by running ./printJenkinsPassword.sh located in the home directory of the EC2 instance"
# echo -e "${COLOR_NONE}"

# Login to EC2 instance
# sleep 12
# ssh -i ~/Desktop/$JENKINS_ID.pem ec2-user@$EC2_IP 'echo "" | sudo -Sv && bash -s' < jenkins/changeMotd.sh >> /dev/null
# sleep 1
# ssh -i ~/Desktop/$JENKINS_ID.pem ec2-user@$EC2_IP
