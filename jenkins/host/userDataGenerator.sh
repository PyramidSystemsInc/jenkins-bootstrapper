#! /bin/bash

function createUserDataScript() {
	cat <<- EOF > jenkins/userData.sh
		#! /bin/bash
		
		PROJECT_NAME=$PROJECT_NAME
		JENKINS_ID=$JENKINS_ID
		JOBS='$JOBS'
		HOSTED_ZONE_NAME=$HOSTED_ZONE_NAME
		CONFIGURE_SSL=$CONFIGURE_SSL
		CONFIGURE_WEBHOOKS=$CONFIGURE_WEBHOOKS
		CONFIGURE_SLAVES=$CONFIGURE_SLAVES
		SLAVE_MIN=$SLAVE_MIN
		
		$USER_DATA_SCRIPT
	EOF
  chmod 755 jenkins/userData.sh
}

function declareVariables() {
  PROJECT_NAME=$1
  JENKINS_ID=$PROJECT_NAME-jenkins
  JOBS=$2
  HOSTED_ZONE_NAME=$3
  CONFIGURE_SSL=$4
  CONFIGURE_WEBHOOKS=$5
  CONFIGURE_SLAVES=$6
  SLAVE_MIN=$7
  USER_DATA_SCRIPT=$(cat ./jenkins/host/userDataTemplate.sh)
}

function deleteUserDataScript() {
  sudo rm jenkins/userData.sh 2> /dev/null
}

declareVariables "$@"
deleteUserDataScript
createUserDataScript
