#! /bin/bash

# Define color palette
COLOR_RED='\033[0;31m'
COLOR_WHITE='\033[0;37m'
COLOR_NONE='\033[0m'

# Ensure a hosted zone name is provided
if [ -z "$1" ]; then
  echo -e "${COLOR_RED}ERROR: Hosted zone name must be provided. Please re-run as follows:${COLOR_NONE}"
  echo -e "${COLOR_WHITE}    ./updateRoute53.sh <HOSTED_ZONE_NAME>"
  echo -e "${COLOR_NONE}"
  exit 2
else
  TARGET_HOSTED_ZONE_NAME=$1
fi

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

# Create JSON structure native to AWS CLI's route53 commands
JENKINS_RECORD_NAME="jenkins.$TARGET_HOSTED_ZONE_NAME"
JENKINS_IP=$(curl ipinfo.io/ip)
CHANGE_BATCH=$(jq -n --arg jenkinsRecordName "$JENKINS_RECORD_NAME" --arg jenkinsIp "$JENKINS_IP" '{
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

# If the hosted zone was found, update the record set for jenkins.<HOSTED_ZONE_NAME>
# Otherwise, alert the user the hosted zone was not found
if [ -z $HOSTED_ZONE_ID ]; then
  echo -e "${COLOR_RED}ERROR: Hosted zone was not found. The trailing '.' is required${COLOR_NONE}"
  echo ""
else
  aws route53 change-resource-record-sets --hosted-zone $HOSTED_ZONE_ID --change-batch "$CHANGE_BATCH"
fi
