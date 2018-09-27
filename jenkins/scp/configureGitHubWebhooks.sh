#! /bin/bash

# Remove the temporary webhook payload file
function cleanup() {
  rm /home/ec2-user/webhook.json
}

# Create payload body to be sent to api.github.com
# Note: It should be the same for all GitHub repositories because it just points to Jenkins
function createGitHubPayload() {
	touch /home/ec2-user/webhook.json
	cat <<- EOF > /home/ec2-user/webhook.json
	{
		"name": "web",
		"active": true,
		"events": [
			"push"
		],
		"config": {
			"url": "https://$DOMAIN/github-webhook/",
			"content_type": "json"
		}
	}
	EOF
	echo "CREATE_PAYLOAD=true" | sudo tee --append /configurationProgress.sh
}

# Create a webhook for each unique URL in the jobs.json file
function createWebhooks() {
  JOB_COUNT=$(cat jobs.json | jq '.jobs | length')
  GITHUB_URLS=()
  for (( JOB_INDEX=0; JOB_INDEX<JOB_COUNT; JOB_INDEX++ )) do
    GITHUB_URL=$(sed -e 's/^"//' -e 's/"$//' <<< $(cat jobs.json | jq '.jobs['"$JOB_INDEX"'].git.url'))
    GITHUB_URL_COUNT=${#GITHUB_URLS[@]}
    GITHUB_URL_UNIQUE=true
    for (( GITHUB_URL_INDEX=0; GITHUB_URL_INDEX<GITHUB_URL_COUNT; GITHUB_URL_INDEX++ )) do
      if [ ${GITHUB_URLS[$GITHUB_URL_INDEX]} == $GITHUB_URL ]; then
        GITHUB_URL_UNIQUE=false
      fi
    done
    if [ $GITHUB_URL_UNIQUE == true ]; then
      GITHUB_URLS+=($GITHUB_URL)
      GITHUB_USERNAME=$(sed -e 's/^"//' -e 's/"$//' <<< $(cat jobs.json | jq '.jobs['"$JOB_INDEX"'].git.credentials.username'))
      GITHUB_PASSWORD=$(sed -e 's/^"//' -e 's/"$//' <<< $(cat jobs.json | jq '.jobs['"$JOB_INDEX"'].git.credentials.password'))
      GITHUB_REPOSITORY=$(sed -e 's/^https:\/\/github.com\///' -e 's/.git$//' <<< $(echo $GITHUB_URL))
      if [ $GITHUB_USERNAME == "null" ]; then
        curl -X POST -d @/home/ec2-user/webhook.json https://api.github.com/repos/$GITHUB_REPOSITORY/hooks
      else
        curl -X POST -d @/home/ec2-user/webhook.json -u $GITHUB_USERNAME:$GITHUB_PASSWORD https://api.github.com/repos/$GITHUB_REPOSITORY/hooks
      fi
    fi
  done
  echo "CREATE_WEBHOOKS=true" | sudo tee --append /configurationProgress.sh
}

# Ensure a hosted zone name is provided
function ensureHostedZoneNameProvided() {
  if [ -z "$1" ]; then
    echo -e "${COLOR_RED}ERROR: Hosted zone name must be provided. Please re-run as follows:${COLOR_NONE}"
    echo -e "${COLOR_WHITE}    ./configureSsl.sh <HOSTED_ZONE_NAME>"
    echo -e "${COLOR_NONE}"
    exit 2
  else
    HOSTED_ZONE_NAME=$1
  fi
}

# Record this script ran successfully
function recordSuccessfulRun() {
  echo "GITHUB_WEBHOOKS_CONFIGURED=true" | sudo tee --append /configurationProgress.sh
}

# Convert hosted zone name into our valid domain (strip trailing '.' and prepend 'jenkins.')
function setDomain() {
  DOMAIN=$(sed -e 's/.$//' <<< $(echo jenkins.$HOSTED_ZONE_NAME))
}

ensureHostedZoneNameProvided "$@"
setDomain
createGitHubPayload
createWebhooks
cleanup
recordSuccessfulRun
