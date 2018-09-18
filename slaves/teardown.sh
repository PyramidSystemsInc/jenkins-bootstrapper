#! /bin/bash

PROJECT_NAME=$1
sudo rm ~/Desktop/$PROJECT_NAME-jenkins-slaves.pem
aws --region us-east-2 ec2 delete-key-pair --key-name $PROJECT_NAME-jenkins-slaves
ecs-cli compose down --cluster-config $PROJECT_NAME-jenkins-slaves
ecs-cli down --force --cluster-config $PROJECT_NAME-jenkins-slaves
