#! /bin/bash

# Ensure a hosted zone name is provided
if [ -z "$1" ]; then
  echo -e "${COLOR_RED}ERROR: Hosted zone name must be provided. Please re-run as follows:${COLOR_NONE}"
  echo -e "${COLOR_WHITE}    ./configureSsl.sh <HOSTED_ZONE_NAME>"
  echo -e "${COLOR_NONE}"
  exit 2
else
  HOSTED_ZONE_NAME=$1
fi

# Convert hosted zone name into our valid domain (strip trailing '.' and prepend 'jenkins.')
DOMAIN=$(sed -e 's/.$//' <<< $(echo jenkins.$HOSTED_ZONE_NAME))

# Create payload body to be sent to api.github.com
touch /home/ec2-user/webhook.json
sudo ed -s /home/ec2-user/webhook.json >> /dev/null <<EOF
i
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
.
w
EOF

# Get a list of unique Git URLs from the jobs.json file
JOB_COUNT=$(cat jobs.json | jq '.jobs | length')
GIT_URLS=()
for (( JOB_INDEX=0; JOB_INDEX<JOB_COUNT; JOB_INDEX++ )) do
  GIT_URL=$(sed -e 's/^"//' -e 's/"$//' <<< $(cat jobs.json | jq '.jobs['"$JOB_INDEX"'].git.url'))
  GIT_URL_COUNT=${#GIT_URLS[@]}
  GIT_URL_UNIQUE=true
  for (( GIT_URL_INDEX=0; GIT_URL_INDEX<GIT_URL_COUNT; GIT_URL_INDEX++ )) do
    if [ ${GIT_URLS[$GIT_URL_INDEX]} == $GIT_URL ]; then
      GIT_URL_UNIQUE=false
    fi
  done
  if [ $GIT_URL_UNIQUE == true ]; then
    GIT_URLS+=($GIT_URL)
  fi
done
echo ${GIT_URLS[@]}

# For each unique Git URL in the jobs.json file, create a webhook to jenkins.<HOSTED_ZONE_NAME>
GIT_URL_COUNT=${#GIT_URLS[@]}
for (( GIT_URL_INDEX=0; GIT_URL_INDEX<GIT_URL_COUNT; GIT_URL_INDEX++ )) do
  # WHERE I LEFT OFF
  # curl -X POST -d @/home/ec2-user/webhook.json -u $GITHUB_USERNAME:$GITHUB_PASSWORD https://api.github.com/repos/$GITHUB_REPOSITORY/hooks
done

rm /home/ec2-user/webhook.json
