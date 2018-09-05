#! /bin/bash

PROJECT_NAME=$1
INSTANCES_DESCRIPTION=$(aws ec2 --region us-east-2 describe-instances)
INSTANCE_COUNT=$(echo $INSTANCES_DESCRIPTION | jq '.Reservations | length')
for (( INSTANCE_INDEX=0; INSTANCE_INDEX<INSTANCE_COUNT; INSTANCE_INDEX++ )) do
  INSTANCE_DESCRIPTION=$(echo $INSTANCES_DESCRIPTION | jq '.Reservations['"$INSTANCE_INDEX"'].Instances[0]')
  INSTANCE_STATE=$(echo $INSTANCE_DESCRIPTION | jq '.State.Name')
  if [ $INSTANCE_STATE == '"running"' ]; then
    INSTANCE_KEY=$(sed -e 's/^"//' -e 's/"$//' <<< $(echo $INSTANCE_DESCRIPTION | jq '.KeyName'))
    SELENIUM_KEY=$PROJECT_NAME-selenium
    if [ $INSTANCE_KEY == $SELENIUM_KEY ]; then
      SELENIUM_IP_ADDRESS=$(sed -e 's/^"//' -e 's/"$//' <<< $(echo $INSTANCE_DESCRIPTION | jq '.NetworkInterfaces[0].Association.PublicIp'))
      echo "$SELENIUM_IP_ADDRESS selenium" | sudo tee --append /etc/hosts
    fi
  fi
done
