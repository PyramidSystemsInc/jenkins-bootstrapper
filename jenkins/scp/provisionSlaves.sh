#! /bin/bash

# NOTE: This file is run every 20 seconds via /var/spool/cron/root
# Depending on the size of the build queue, this script can kick off the provisioning of a new Jenkins slave
# TODO: Lop off the top of .build-queue-size if it is more than 360 lines (two hours worth of records)

# Get a Jenkins "crumb" for authentication
function fetchJenkinsCrumb() {
  JENKINS_CRUMB=$(curl -s "http://admin:"$JENKINS_PASSWORD"@localhost:8080/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)")
}

# Run the `createNewSlave.sh` script if the build queue has extra work
# Note: The `.slave-creation-lock` file prevents this function from launching a new slave if one is already being launched
function kickoffSlaveCreationIfBuildQueueHasWork() {
  if [[ $CURRENT_BUILD_QUEUE_SIZE -gt 0 ]]; then
    if [ ! -f /home/ec2-user/slaves/.slave-creation-lock ]; then
      touch /home/ec2-user/slaves/.slave-creation-lock
      /home/ec2-user/slaves/createNewSlave.sh
    fi 
  else
    if [ -f /home/ec2-user/slaves/.slave-creation-lock ]; then
      rm /home/ec2-user/slaves/.slave-creation-lock
    fi
  fi
}

# Query for the current build queue size
function getCurrentBuildQueueSize() {
  CURRENT_BUILD_QUEUE_SIZE=$(curl -H $JENKINS_CRUMB -L -s -u admin:$JENKINS_PASSWORD http://localhost:8080/queue/api/json | jq ".items | length")
}

# Set the Jenkins password variable
function setJenkinsPassword() {
  JENKINS_PASSWORD=$(/home/ec2-user/printJenkinsPassword.sh)
}

setJenkinsPassword
fetchJenkinsCrumb
getCurrentBuildQueueSize
kickoffSlaveCreationIfBuildQueueHasWork
