#! /bin/bash

# NOTE: This file is run every 20 seconds via /var/spool/cron/root
# Depending on the size of the build queue, this script can kick off the provisioning of a new Jenkins slave
# TODO: Lop off the top of .build-queue-size if it is more than 360 lines (two hours worth of records)

# Get a Jenkins "crumb" for authentication
function fetchJenkinsCrumb() {
  JENKINS_CRUMB=$(curl -s "http://admin:"$JENKINS_PASSWORD"@localhost:8080/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)")
}

# Look to the `.build-queue-size` for the two most recent measurements
function getTwoMostRecentBuildQueueMeasurements() {
  BUILD_QUEUE_MEASURE_ONE=$(tail -n 2 /home/ec2-user/slaves/.build-queue-size | head -n 1)
  BUILD_QUEUE_MEASURE_TWO=$(tail -n 1 /home/ec2-user/slaves/.build-queue-size)
}

# Run the `createNewSlave.sh` script if the build queue has extra work
# Note: The `.slave-creation-lock` file prevents this function from launching a new slave if one is already being launched
function kickoffSlaveCreationIfBuildQueueHasWork() {
  if [[ $BUILD_QUEUE_MEASURE_ONE -gt 0 ]] && [[ $BUILD_QUEUE_MEASURE_TWO -gt 0 ]]; then
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

# Record the current build queue size in the `.build-queue-size` log
function recordCurrentBuildQueueSize() {
  echo $(curl -H $JENKINS_CRUMB -L -s -u admin:$JENKINS_PASSWORD http://localhost:8080/queue/api/json | jq ".items | length") >> /home/ec2-user/slaves/.build-queue-size
}

# Set the Jenkins password variable
function setJenkinsPassword() {
  JENKINS_PASSWORD=$(/home/ec2-user/printJenkinsPassword.sh)
}

setJenkinsPassword
fetchJenkinsCrumb
recordCurrentBuildQueueSize
getTwoMostRecentBuildQueueMeasurements
kickoffSlaveCreationIfBuildQueueHasWork
