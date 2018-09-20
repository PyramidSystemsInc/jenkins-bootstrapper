#! /bin/bash

PROJECT_NAME=$1

# Login to ECR repositories
$(aws ecr get-login --no-include-email --region us-east-2)

# Query for or create ECR repository
TARGET='jenkins-slave'
ECR_REPOSITORIES=$(aws ecr describe-repositories | jq '.repositories')
ECR_REPOSITORY_COUNT=$(echo $ECR_REPOSITORIES | jq '. | length')
for (( ECR_REPOSITORY_INDEX=0; ECR_REPOSITORY_INDEX<ECR_REPOSITORY_COUNT; ECR_REPOSITORY_INDEX++ )) do
  ECR_REPOSITORY_URI=$(echo $ECR_REPOSITORIES | jq '.['"$ECR_REPOSITORY_INDEX"'].repositoryUri')
  if [[ $ECR_REPOSITORY_URI =~ $TARGET ]]; then
    ECR_REPOSITORY_NAME=$(sed -e 's/^"//g' -e 's/"$//g' <<< $ECR_REPOSITORY_URI)
    break
  fi
done
if [ -z $ECR_REPOSITORY_NAME ]; then
  NEW_ECR_REPOSITORY=$(aws ecr create-repository --repository-name jenkins-slave | jq '.repository.repositoryUri')
  ECR_REPOSITORY_NAME=$(sed -e 's/^"//g' -e 's/"$//g' <<< $NEW_ECR_REPOSITORY)
fi

# Build the Docker image
docker build -t $ECR_REPOSITORY_NAME:$PROJECT_NAME .

# Push the Docker image
docker push $ECR_REPOSITORY_NAME:$PROJECT_NAME
