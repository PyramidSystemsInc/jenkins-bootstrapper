#! /bin/bash

# Create Jenkins security group
SECURITY_GROUP_ID=$(sed -e 's/^"//' -e 's/"$//' <<< $(echo $(aws ec2 create-security-group --group-name rispd-jenkins --description "Created by jenkins-bootstrapper") | jq '.GroupId'))
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 443 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 8080 --cidr 0.0.0.0/0
