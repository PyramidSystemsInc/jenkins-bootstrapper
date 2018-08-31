#! /bin/bash

INSTANCES_DESCRIPTION=$(aws ec2 --region us-east-2 describe-instances)
INSTANCE_COUNT=$(echo $INSTANCES_DESCRIPTION | jq '.Reservations | length')
for (( INSTANCE_INDEX=0; INSTANCE_INDEX<INSTANCE_COUNT; INSTANCE_INDEX++ )) do
  INSTANCE_DESCRIPTION=$(echo $INSTANCES_DESCRIPTION | jq '.Reservations['"$INSTANCE_INDEX"'].Instances[0]')
  INSTANCE_STATE=$(echo $INSTANCE_DESCRIPTION | jq '.State.Name')
  if [ $INSTANCE_STATE == '"running"' ]; then
    INSTANCE_KEY=$(echo $INSTANCE_DESCRIPTION | jq '.KeyName')
    if [ $INSTANCE_KEY == '"rispd-selenium"' ]; then
      echo $PROJECT_NAME
    fi
  fi
done
