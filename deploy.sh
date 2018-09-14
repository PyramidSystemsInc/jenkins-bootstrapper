#! /bin/bash

echo -e ""

# Define color palette
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[0;33m'
COLOR_WHITE='\033[0;37m'
COLOR_NONE='\033[0m'

# Set default input values
HOSTED_ZONE=false
CONFIGURE_SSL=true
DEPLOY_SELENIUM=true
DEPLOY_SONARQUBE=true
CONFIGURE_WEBHOOKS=true

# Handle input
while [ "$#" -gt 0 ]; do
  case "$1" in
    -p) PROJECT_NAME="$2"; shift 2;;
    --project-name) PROJECT_NAME="$2"; shift 2;;
    -j) JOBS=$(echo $(cat $2) | jq '.'); shift 2;;
    --jobs) JOBS=$(echo $(cat $2) | jq '.'); shift 2;;
    --aws-access-key) AWS_ACCESS_KEY="$2"; ATTEMPTED_MANUAL_KEYS=true; shift 2;;
    --aws-secret-key) AWS_SECRET_KEY="$2"; ATTEMPTED_MANUAL_KEYS=true; shift 2;;
    -i) AWS_IAM_ROLE="$2"; shift 2;;
    --iam-role) AWS_IAM_ROLE="$2"; shift 2;;
    -z) HOSTED_ZONE="$2"; shift 2;;
    --hosted-zone) HOSTED_ZONE="$2"; shift 2;;
    --skip-ssl) CONFIGURE_SSL=false; shift 1;;
    --skip-selenium) DEPLOY_SELENIUM=false; shift 1;;
    --skip-sonarqube) DEPLOY_SONARQUBE=false; shift 1;;
    --skip-webhooks) CONFIGURE_WEBHOOKS=false; shift 1;;
    -h) HELP_WANTED=true; shift 1;;
    --help) HELP_WANTED=true; shift 1;;
    -*) echo "unknown option: $1" >&2; exit 1;;
    *) args+="$1 "; shift 1;;
  esac
done
if [ ${#args} -gt 0 ]; then
  echo -e "${COLOR_WHITE}NOTICE: The following arguments were ignored: ${args}"
  echo -e "${COLOR_NONE}"
fi

# Show help if `-h` or `--help` flags were provided 
if [ "$HELP_WANTED" == "true" ]; then
  # TODO
  echo -e "I am a help message"
  echo -e ""
  exit 2
fi

# Ensure a project name is provided
if [ -z "$PROJECT_NAME" ]; then
  echo -e "${COLOR_RED}ERROR: Project name must be provided. Please re-run as follows:${COLOR_NONE}"
  echo -e "${COLOR_WHITE}    ./deploy.sh -p <PROJECT_NAME> -j <JOBS_FILE_LOCATION>"
  echo -e "    -OR-"
  echo -e "    ./deploy.sh --help"
  echo -e "${COLOR_NONE}"
  exit 2
fi

# Ensure a jobs.json is provided
if [ -z "$JOBS" ] || [ $(echo $JOBS | jq '.jobs | length') -lt 1 ]; then
  echo -e "${COLOR_RED}ERROR: Jenkins jobs (jobs.json) must be provided. Please re-run as follows:${COLOR_NONE}"
  echo -e "${COLOR_WHITE}    ./deploy.sh -p <PROJECT_NAME> -j <JOBS_FILE_LOCATION>"
  echo -e "    -OR-"
  echo -e "    ./deploy.sh --help"
  echo -e "${COLOR_NONE}"
  exit 2
fi

# Attempt to load AWS credentials if not provided
# Otherwise, create or overwrite AWS credentials with the provided credentials
if [ -z "$AWS_ACCESS_KEY" ] || [ -z "$AWS_SECRET_KEY" ]; then
  if [ "$ATTEMPTED_MANUAL_KEYS" == true ]; then
    echo -e "${COLOR_YELLOW}WARNING: It appears AWS credentials were attempted to be passed via flags, but one or the other is missing"
    echo -e "    If providing keys through flags, provide both \`--aws-access-key <VALUE>\` and \`--aws-secret-key <VALUE>\`"
    echo -e "${COLOR_NONE}"
  fi
  echo -e "${COLOR_WHITE}NOTICE: Using existing AWS credentials (found at ~/.aws/credentials)"
  echo -e "${COLOR_NONE}"
  AWS_CREDENTIALS=($(cat ~/.aws/credentials))
  AWS_ACCESS_KEY=${AWS_CREDENTIALS[3]}
  AWS_SECRET_KEY=${AWS_CREDENTIALS[6]}
  if [ ${#AWS_ACCESS_KEY} != 20 ] || [ ${#AWS_SECRET_KEY} != 40 ]; then
    echo -e ""
    echo -e "${COLOR_RED}ERROR: Could not find a valid set of credentials passed in as flags or located at ~/.aws/credentials"
    echo -e "Please re-run with AWS credentials specified as follows:${COLOR_NONE}"
    echo -e "${COLOR_WHITE}    ./deploy.sh -p <PROJECT_NAME> --aws-access-key <AWS_ACCESS_KEY> --aws-secret-key <AWS_SECRET_KEY>"
    echo -e ""
    echo -e "${COLOR_RED}For Example:"
    echo -e "${COLOR_WHITE}    ./deploy.sh -p rispd --aws-access-key aeZ87sVkkdjfs --aws-secret-key askdf832ls97smvms8o"
    echo -e "${COLOR_NONE}"
    exit 2
  fi
else
  echo -e "${COLOR_WHITE}NOTICE: Overwriting AWS credentials found at ~/.aws/credentials with the values provided"
  echo -e "${COLOR_NONE}"
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
./jenkins/userDataGenerator.sh $PROJECT_NAME "$JOBS" $HOSTED_ZONE $AWS_ACCESS_KEY $AWS_SECRET_KEY $CONFIGURE_SSL $CONFIGURE_WEBHOOKS
./jenkins/createInstance.sh $PROJECT_NAME $AWS_IAM_ROLE

# Create Selenium Grid ECS Cluster
if [ "$DEPLOY_SELENIUM" == "true" ]; then
  cd selenium
  rm -f logs/clusterCreate.log logs/taskCreate.log
  ./deploy.sh $PROJECT_NAME >logs/clusterCreate.log 2>logs/taskCreate.log &
  cd ..
fi

# Create SonarQube ECS cluster
# TODO
#if [ "$DEPLOY_SONARQUBE" == "true" ]; then
#  echo I am configuring SonarQube now
#else
#  echo Skipping SonarQube
#fi

# Wait until the EC2 instance has a status of "running"
echo -e ""
echo -e "Waiting on Jenkins EC2 instance to start up"
WAITING_ON_JENKINS=true
while [ "$WAITING_ON_JENKINS" == "true" ]; do
  INSTANCE_STATUSES=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].[State.Name,Tags[?Key==`Name`].Value,PublicIpAddress]')
  INSTANCE_COUNT=$(echo $INSTANCE_STATUSES | jq '. | length')
  for (( INSTANCE_INDEX=0; INSTANCE_INDEX<INSTANCE_COUNT; INSTANCE_INDEX++ )) do
    if [ "$(echo $INSTANCE_STATUSES | jq '.['"$INSTANCE_INDEX"'][0][0]')" == "\"running\"" ]; then
      if [ "$(echo $INSTANCE_STATUSES | jq '.['"$INSTANCE_INDEX"'][0][1][0]')" == "\"${PROJECT_NAME}-jenkins\"" ]; then
        WAITING_ON_JENKINS=false
        JENKINS_IP=$(sed -e 's/^"//' -e 's/"$//' <<< $(echo $INSTANCE_STATUSES | jq '.['"$INSTANCE_INDEX"'][0][2]'))
      fi
    fi
  done
done
echo -e "Jenkins EC2 instance has started"
echo -e ""
echo -e "Configuring Jenkins EC2 instance. When prompted to connect to Jenkins, type 'yes' to allow the connection and monitor the configuration progress"
sleep 20

# Monitor the Jenkins configuration process by running a script over SSH
ssh -i ~/Desktop/$PROJECT_NAME-jenkins.pem ec2-user@${JENKINS_IP} 'echo "" | sudo -Sv && bash -s' < jenkins/monitorProgress.sh

# Change Amazon's default "message of the day" and login to Jenkins EC2 instance
ssh -i ~/Desktop/$PROJECT_NAME-jenkins.pem ec2-user@${JENKINS_IP} 'echo "" | sudo -Sv && bash -s' < jenkins/changeMotd.sh >> /dev/null
sleep 2
ssh -i ~/Desktop/$PROJECT_NAME-jenkins.pem ec2-user@${JENKINS_IP}

echo -e ""
