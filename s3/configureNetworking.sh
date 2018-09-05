#! /bin/bash

# Define color palette
COLOR_RED='\033[0;31m'
COLOR_WHITE='\033[0;37m'
COLOR_NONE='\033[0m'

# Ensure a project name is provided
if [ -z "$1" ]; then
  echo -e "${COLOR_RED}ERROR: Project name must be provided. Please re-run as follows:${COLOR_NONE}"
  echo -e "${COLOR_WHITE}    ./configureNetworking.sh <PROJECT_NAME> <HOSTED_ZONE_NAME>"
  echo -e "${COLOR_NONE}"
  exit 2
else
  PROJECT_NAME=$1
fi

# Ensure a hosted zone name is provided
if [ -z "$2" ]; then
  echo -e "${COLOR_RED}ERROR: Hosted zone name must be provided. Please re-run as follows:${COLOR_NONE}"
  echo -e "${COLOR_WHITE}    ./configureNetworking.sh <PROJECT_NAME> <HOSTED_ZONE_NAME>"
  echo -e "${COLOR_NONE}"
  exit 2
else
  TARGET_HOSTED_ZONE_NAME=$2
fi

# Find the public IP address of the Selenium grid and add it to the hosts file as "selenium"
INSTANCES_DESCRIPTION=$(aws ec2 --region us-east-2 describe-instances)
INSTANCE_COUNT=$(echo $INSTANCES_DESCRIPTION | jq '.Reservations | length')
for (( INSTANCE_INDEX=0; INSTANCE_INDEX<INSTANCE_COUNT; INSTANCE_INDEX++ )) do
  INSTANCE_DESCRIPTION=$(echo $INSTANCES_DESCRIPTION | jq '.Reservations['"$INSTANCE_INDEX"'].Instances[0]')
  INSTANCE_STATE=$(echo $INSTANCE_DESCRIPTION | jq '.State.Name')
  if [ $INSTANCE_STATE == '"running"' ]; then
    INSTANCE_KEY=$(sed -e 's/^"//' -e 's/"$//' <<< $(echo $INSTANCE_DESCRIPTION | jq '.KeyName'))
    SELENIUM_KEY=$PROJECT_NAME-selenium
    if [ $INSTANCE_KEY == $SELENIUM_KEY ]; then
      SELENIUM_IP=$(sed -e 's/^"//' -e 's/"$//' <<< $(echo $INSTANCE_DESCRIPTION | jq '.NetworkInterfaces[0].Association.PublicIp'))
      echo "$SELENIUM_IP selenium" | sudo tee --append /etc/hosts
    fi
  fi
done

# Find the existing hosted zone ID of the hosted zone name provided
HOSTED_ZONES=$(aws route53 list-hosted-zones)
HOSTED_ZONES_COUNT=$(aws route53 list-hosted-zones | jq '.HostedZones | length')
for (( HOSTED_ZONE_INDEX=0; HOSTED_ZONE_INDEX<HOSTED_ZONES_COUNT; HOSTED_ZONE_INDEX++ )) do
  HOSTED_ZONE=$(echo $HOSTED_ZONES | jq '.HostedZones['"$HOSTED_ZONE_INDEX"']')
  HOSTED_ZONE_NAME=$(sed -e 's/^"//' -e 's/"$//' <<< $(echo $HOSTED_ZONE | jq '.Name'))
  if [ $HOSTED_ZONE_NAME == $TARGET_HOSTED_ZONE_NAME ]; then
    HOSTED_ZONE_ID=$(sed -e 's/^"//' -e 's/"$//' <<< $(echo $HOSTED_ZONE | jq '.Id'))
  fi
done

# If the hosted zone was not found, alert the user and exit
if [ -z $HOSTED_ZONE_ID ]; then
  echo -e "${COLOR_RED}ERROR: Hosted zone was not found. The trailing '.' is required${COLOR_NONE}"
  echo ""
  exit 2
fi

# Create/update a record in the hosted zone for jenkins.<HOSTED_ZONE_NAME>
JENKINS_RECORD_NAME="jenkins.$TARGET_HOSTED_ZONE_NAME"
JENKINS_IP=$(curl ipinfo.io/ip)
JENKINS_CHANGE_BATCH=$(jq -n --arg jenkinsRecordName "$JENKINS_RECORD_NAME" --arg jenkinsIp "$JENKINS_IP" '{
  Changes: [
    {
      Action: "UPSERT",
      ResourceRecordSet: {
        Name: $jenkinsRecordName,
        Type: "A",
        TTL: 300,
        ResourceRecords: [
          {
            Value: $jenkinsIp
          }
        ]
      }
    }
  ]
}')
aws route53 change-resource-record-sets --hosted-zone $HOSTED_ZONE_ID --change-batch "$JENKINS_CHANGE_BATCH"

# If a Selenium IP was found above, create/update a record in the hosted zone for selenium.<HOSTED_ZONE_NAME>
if [ -z $SELENIUM_IP ]; then
  echo -e "${COLOR_RED}ERROR: The Selenium instance's IP address could not be found"
  echo "${COLOR_NONE}"
else
  SELENIUM_RECORD_NAME="selenium.$TARGET_HOSTED_ZONE_NAME"
  SELENIUM_CHANGE_BATCH=$(jq -n --arg seleniumRecordName "$SELENIUM_RECORD_NAME" --arg seleniumIp "$SELENIUM_IP" '{
    Changes: [
      {
        Action: "UPSERT",
        ResourceRecordSet: {
          Name: $seleniumRecordName,
          Type: "A",
          TTL: 300,
          ResourceRecords: [
            {
              Value: $seleniumIp
            }
          ]
        }
      }
    ]
  }')
  aws route53 change-resource-record-sets --hosted-zone $HOSTED_ZONE_ID --change-batch "$SELENIUM_CHANGE_BATCH"
fi
