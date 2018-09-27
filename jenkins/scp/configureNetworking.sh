#! /bin/bash

# Define color palette
function defineColorPalette() {
  COLOR_RED='\033[0;31m'
  COLOR_WHITE='\033[0;37m'
  COLOR_NONE='\033[0m'
}

# Ensure a project name is provided
function ensureProjectNameProvided() {
  if [ -z "$1" ]; then
    echo -e "${COLOR_RED}ERROR: Project name must be provided. Please re-run as follows:${COLOR_NONE}"
    echo -e "${COLOR_WHITE}    ./configureNetworking.sh <PROJECT_NAME> <HOSTED_ZONE_NAME>"
    echo -e "${COLOR_NONE}"
    exit 2
  else
    PROJECT_NAME=$1
  fi
}

# Ensure a hosted zone name is provided
function ensureHostedZoneNameProvided() {
  if [ -z "$2" ]; then
    echo -e "${COLOR_RED}ERROR: Hosted zone name must be provided. Please re-run as follows:${COLOR_NONE}"
    echo -e "${COLOR_WHITE}    ./configureNetworking.sh <PROJECT_NAME> <HOSTED_ZONE_NAME>"
    echo -e "${COLOR_NONE}"
    exit 2
  else
    TARGET_HOSTED_ZONE_NAME=$2
  fi
}

# Find the corresponding hosted zone ID of the hosted zone name provided
function findHostedZoneId() {
  HOSTED_ZONES=$(aws route53 list-hosted-zones)
  HOSTED_ZONES_COUNT=$(aws route53 list-hosted-zones | jq '.HostedZones | length')
  for (( HOSTED_ZONE_INDEX=0; HOSTED_ZONE_INDEX<HOSTED_ZONES_COUNT; HOSTED_ZONE_INDEX++ )) do
    HOSTED_ZONE=$(echo $HOSTED_ZONES | jq '.HostedZones['"$HOSTED_ZONE_INDEX"']')
    HOSTED_ZONE_NAME=$(sed -e 's/^"//' -e 's/"$//' <<< $(echo $HOSTED_ZONE | jq '.Name'))
    if [ $HOSTED_ZONE_NAME == $TARGET_HOSTED_ZONE_NAME ]; then
      HOSTED_ZONE_ID=$(sed -e 's/^"//' -e 's/"$//' <<< $(echo $HOSTED_ZONE | jq '.Id'))
    fi
  done
  echo "FIND_HOSTED_ZONE_ID=true" | sudo tee --append /configurationProgress.sh
}

# If the hosted zone was not found, alert the user and exit
function errorIfHostedZoneNotFound() {
  if [ -z $HOSTED_ZONE_ID ]; then
    echo -e "${COLOR_RED}ERROR: Hosted zone was not found. The trailing '.' is required${COLOR_NONE}"
    echo ""
    echo "NETWORKING_CONFIGURED=false" | sudo tee --append /configurationProgress.sh
    exit 2
  fi
}

# Create/update a record in the hosted zone for jenkins.<HOSTED_ZONE_NAME>
function createJenkinsHostedZoneRecord() {
  JENKINS_RECORD_NAME="jenkins.$TARGET_HOSTED_ZONE_NAME"
  JENKINS_IP=$(curl ipinfo.io/ip)
  JENKINS_CHANGE_BATCH=$(jq -n --arg jenkinsRecordName "$JENKINS_RECORD_NAME" --arg jenkinsIp "$JENKINS_IP" '{
    Changes: [
      {
        Action: "UPSERT",
        ResourceRecordSet: {
          Name: $jenkinsRecordName,
          Type: "A",
          TTL: 300,
          ResourceRecords: [
            {
              Value: $jenkinsIp
            }
          ]
        }
      }
    ]
  }')
  aws route53 change-resource-record-sets --hosted-zone $HOSTED_ZONE_ID --change-batch "$JENKINS_CHANGE_BATCH"
  echo "CREATE_JENKINS_RECORD=true" | sudo tee --append /configurationProgress.sh
}

# Find the public IP address of the Selenium grid
function findSeleniumIp() {
  INSTANCES_DESCRIPTION=$(aws ec2 --region us-east-2 describe-instances)
  INSTANCE_COUNT=$(echo $INSTANCES_DESCRIPTION | jq '.Reservations | length')
  for (( INSTANCE_INDEX=0; INSTANCE_INDEX<INSTANCE_COUNT; INSTANCE_INDEX++ )) do
    INSTANCE_DESCRIPTION=$(echo $INSTANCES_DESCRIPTION | jq '.Reservations['"$INSTANCE_INDEX"'].Instances[0]')
    INSTANCE_STATE=$(echo $INSTANCE_DESCRIPTION | jq '.State.Name')
    if [ $INSTANCE_STATE == '"running"' ]; then
      INSTANCE_KEY=$(sed -e 's/^"//' -e 's/"$//' <<< $(echo $INSTANCE_DESCRIPTION | jq '.KeyName'))
      SELENIUM_KEY=$PROJECT_NAME-selenium
      if [ $INSTANCE_KEY == $SELENIUM_KEY ]; then
        SELENIUM_IP=$(sed -e 's/^"//' -e 's/"$//' <<< $(echo $INSTANCE_DESCRIPTION | jq '.NetworkInterfaces[0].Association.PublicIp'))
      fi
    fi
  done
}

# If a Selenium IP was found above, create/update a record in the hosted zone for selenium.<HOSTED_ZONE_NAME> and add Selenium to the hosts file
function createSeleniumHostedZoneRecord() {
  if [ -z $SELENIUM_IP ]; then
    echo -e "${COLOR_RED}ERROR: The Selenium instance's IP address could not be found"
    echo "${COLOR_NONE}"
    echo "ADD_SELENIUM_TO_HOSTS=false" | sudo tee --append /configurationProgress.sh
    echo "CREATE_SELENIUM_RECORD=false" | sudo tee --append /configurationProgress.sh
    echo "NETWORKING_CONFIGURED=false" | sudo tee --append /configurationProgress.sh
  else
    SELENIUM_RECORD_NAME="selenium.$TARGET_HOSTED_ZONE_NAME"
    SELENIUM_CHANGE_BATCH=$(jq -n --arg seleniumRecordName "$SELENIUM_RECORD_NAME" --arg seleniumIp "$SELENIUM_IP" '{
      Changes: [
        {
          Action: "UPSERT",
          ResourceRecordSet: {
            Name: $seleniumRecordName,
            Type: "A",
            TTL: 300,
            ResourceRecords: [
              {
                Value: $seleniumIp
              }
            ]
          }
        }
      ]
    }')
    aws route53 change-resource-record-sets --hosted-zone $HOSTED_ZONE_ID --change-batch "$SELENIUM_CHANGE_BATCH"
    echo "$SELENIUM_IP selenium" | sudo tee --append /etc/hosts
    echo "ADD_SELENIUM_TO_HOSTS=true" | sudo tee --append /configurationProgress.sh
    echo "CREATE_SELENIUM_RECORD=true" | sudo tee --append /configurationProgress.sh
    echo "NETWORKING_CONFIGURED=true" | sudo tee --append /configurationProgress.sh
  fi
}

# Restart NGINX
function restartNginx() {
  sudo service nginx restart
}

# Convert hosted zone name into our valid domain (strip trailing '.' and prepend 'jenkins.')
function setServerName() {
  SERVER_NAME=$(sed -e 's/.$//' <<< $(echo jenkins.$TARGET_HOSTED_ZONE_NAME))
}

# Replace NGINX config file
function overwriteNginxConfig() {
  sudo rm /etc/nginx/nginx.conf
  sudo mkdir -p /etc/nginx/
  sudo touch /etc/nginx/nginx.conf
  cat <<- EOF > /etc/nginx/nginx.conf
		user nginx;
		worker_processes auto;
		error_log /var/log/nginx/error.log;
		pid /var/run/nginx.pid;
		
		include /usr/share/nginx/modules/*.conf;
		
		events {
		  worker_connections 1024;
		}
		
		http {
		  proxy_send_timeout  120;
		  proxy_read_timeout  300;
		  proxy_buffering     off;
		  keepalive_timeout   5 5;
		  tcp_nodelay         on;
		
		  server {
		    listen *:80;
		    server_name $SERVER_NAME;
		
		    client_max_body_size 1G;
		
		    location / {
		      proxy_pass http://localhost:8080/;
		      proxy_set_header Host \$host;
		      proxy_set_header X-Real-IP \$remote_addr;
		      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
		      proxy_set_header X-Forwarded-Proto "https";
		    }
		  }
		}
	EOF
}

defineColorPalette
ensureProjectNameProvided "$@"
ensureHostedZoneNameProvided "$@"
findHostedZoneId
errorIfHostedZoneNotFound
createJenkinsHostedZoneRecord
findSeleniumIp
createSeleniumHostedZoneRecord
setServerName
overwriteNginxConfig
restartNginx
