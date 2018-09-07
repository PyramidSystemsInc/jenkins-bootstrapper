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

# Start Selenium Grid
cd selenium
rm -f logs/clusterCreate.log logs/taskCreate.log
./deploy.sh $PROJECT_NAME >logs/clusterCreate.log 2>logs/taskCreate.log &
cd ..

# Create key pair
aws --region us-east-2 ec2 create-key-pair --key-name $PROJECT_NAME-jenkins --query 'KeyMaterial' --output text > ~/Desktop/$PROJECT_NAME-jenkins.pem
KEY_PAIR=$(cat ~/Desktop/$PROJECT_NAME-jenkins.pem)
if [ ${#KEY_PAIR} == 0 ]; then
  echo -e ""
  echo -e "${COLOR_RED}ERROR: PEM file was unable to be created. Do you have permissions on your AWS account to create key pairs?"
  echo -e "${COLOR_NONE}"
  exit 2
else
  chmod 400 ~/Desktop/$PROJECT_NAME-jenkins.pem
fi

# Install Pulumi dependencies
npm install

# Setup Pulumi
pulumi stack init $PROJECT_NAME-jenkins
pulumi stack select $PROJECT_NAME-jenkins
pulumi config set cloud:provider aws
pulumi config set aws:region us-east-2
pulumi config set cloud-aws:useFargate true
pulumi config set jenkins:projectName $PROJECT_NAME
pulumi config set jenkins:hostedZoneName $HOSTED_ZONE_NAME
pulumi config set jenkins:AWS_ACCESS_KEY_ID $AWS_ACCESS_KEY --secret
pulumi config set jenkins:AWS_SECRET_ACCESS_KEY $AWS_SECRET_KEY --secret

# Launch EC2 instance
pulumi update -y

# Cleanup
rm Pulumi.$PROJECT_NAME-jenkins.yaml

# Login to EC2 instance
EC2_IP=$(pulumi stack output ipAddress)
echo -e "${COLOR_WHITE}NOTICE: Logging into Jenkins EC2 instance with the command:"
echo -e "    ssh -i ~/Desktop/$PROJECT_NAME-jenkins.pem ec2-user@$EC2_IP"
echo -e "${COLOR_NONE}"
echo -e "${COLOR_YELLOW}WARNING: The instance is still being configured so don't freak out if your stuff isn't there yet"
echo -e "         It should finish configuring itself in about a minute and a half"
echo -e "${COLOR_NONE}"
echo -e "${COLOR_WHITE}NOTICE: Once the instance is done being configured, you can reach Jenkins at the following address in your browser:"
echo -e "    $EC2_IP:8080"
echo -e "${COLOR_NONE}"
echo -e "${COLOR_WHITE}NOTICE: This is the webhook URL that must be pasted in to the Payload URL field on GitHub:"
echo -e "    http://$EC2_IP:8080/github-webhook/"
echo -e "${COLOR_NONE}"
echo -e "${COLOR_WHITE}NOTICE: After navigating to the URL above, enter the username \"admin\""
echo -e "        The password can be found by running ./printJenkinsPassword.sh located in the home directory of the EC2 instance"
echo -e "${COLOR_NONE}"
sleep 12
ssh -i ~/Desktop/$PROJECT_NAME-jenkins.pem ec2-user@$EC2_IP 'echo "" | sudo -Sv && bash -s' < util/changeMotd.sh >> /dev/null
sleep 1
ssh -i ~/Desktop/$PROJECT_NAME-jenkins.pem ec2-user@$EC2_IP
