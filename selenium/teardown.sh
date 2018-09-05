#! /bin/bash

PROJECT_NAME=$1
sudo rm ~/Desktop/$PROJECT_NAME-selenium.pem
aws --region us-east-2 ec2 delete-key-pair --key-name $PROJECT_NAME-selenium
ecs-cli compose down --cluster-config $PROJECT_NAME-selenium
ecs-cli down --force --cluster-config $PROJECT_NAME-selenium
