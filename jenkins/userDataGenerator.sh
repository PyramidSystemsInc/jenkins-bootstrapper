#! /bin/bash

PROJECT_NAME=$1
JENKINS_ID=$PROJECT_NAME-jenkins
JOBS=$2
HOSTED_ZONE_NAME=$3
AWS_ACCESS_KEY=$4
AWS_SECRET_KEY=$5
CONFIGURE_SSL=$6
CONFIGURE_WEBHOOKS=$7
USER_DATA_SCRIPT=$(cat ./jenkins/userDataTemplate.sh)
sudo rm jenkins/userData.sh 2> /dev/null
touch jenkins/userData.sh
echo "#! /bin/bash" | tee --append jenkins/userData.sh >> /dev/null
echo "" | tee --append jenkins/userData.sh >> /dev/null
echo "PROJECT_NAME=$PROJECT_NAME" | tee --append jenkins/userData.sh >> /dev/null
echo "JENKINS_ID=$JENKINS_ID" | tee --append jenkins/userData.sh >> /dev/null
echo "JOBS='$JOBS'" | tee --append jenkins/userData.sh >> /dev/null
echo "HOSTED_ZONE_NAME=$HOSTED_ZONE_NAME" | tee --append jenkins/userData.sh >> /dev/null
echo "AWS_ACCESS_KEY=$AWS_ACCESS_KEY" | tee --append jenkins/userData.sh >> /dev/null
echo "AWS_SECRET_KEY=$AWS_SECRET_KEY" | tee --append jenkins/userData.sh >> /dev/null
echo "CONFIGURE_SSL=$CONFIGURE_SSL" | tee --append jenkins/userData.sh >> /dev/null
echo "CONFIGURE_WEBHOOKS=$CONFIGURE_WEBHOOKS" | tee --append jenkins/userData.sh >> /dev/null
echo "" | tee --append jenkins/userData.sh >> /dev/null
echo "$USER_DATA_SCRIPT" | tee --append jenkins/userData.sh >> /dev/null
chmod 755 jenkins/userData.sh
