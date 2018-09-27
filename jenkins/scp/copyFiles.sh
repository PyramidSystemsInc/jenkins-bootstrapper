#! /bin/bash

# Ensure a project name is provided
if [ -z "$1" ]; then
  echo -e "${COLOR_RED}ERROR: Project name must be provided. Please re-run as follows:${COLOR_NONE}"
  echo -e "${COLOR_WHITE}    ./copyFiles.sh <PROJECT_NAME> <JOBS_JSON>"
  echo -e "${COLOR_NONE}"
  exit 2
else
  PROJECT_NAME=$1
fi

# Ensure a jobs config is provided
if [ -z "$2" ]; then
  echo -e "${COLOR_RED}ERROR: Jobs JSON configuration object must be provided. Please re-run as follows:${COLOR_NONE}"
  echo -e "${COLOR_WHITE}    ./copyFiles.sh <PROJECT_NAME> <JOBS_JSON>"
  echo -e "${COLOR_NONE}"
  exit 2
else
  JOBS=$2
fi

# Create file to monitor instance configuring process
sudo touch /configurationProgress.sh
sudo chmod 755 /configurationProgress.sh
echo "#! /bin/bash" | sudo tee --append /configurationProgress.sh
echo "" | sudo tee --append /configurationProgress.sh
echo "CONFIG_PROGRESS_CREATED=true" | sudo tee --append /configurationProgress.sh

# Create CRON jobs to initiate the provisioning of Jenkins slaves
echo -e "$(sudo crontab -l)\n* * * * * /home/ec2-user/provisionSlaves.sh" | sudo crontab -
echo -e "$(sudo crontab -l)\n* * * * * ( sleep 20; /home/ec2-user/provisionSlaves.sh )" | sudo crontab -
echo -e "$(sudo crontab -l)\n* * * * * ( sleep 40; /home/ec2-user/provisionSlaves.sh )" | sudo crontab -

# Create log for Jenkins build queue size
sudo mkdir /home/ec2-user/slaves >> /dev/null
sudo mv /home/ec2-user/createNewSlave.sh /home/ec2-user/slaves/ >> /dev/null
sudo touch /home/ec2-user/slaves/.build-queue-size

# Create jobs.json file
sudo touch /home/ec2-user/jobs.json
sudo chmod 755 /home/ec2-user/jobs.json
echo $JOBS > /home/ec2-user/jobs.json
echo "JOBS_JSON_CREATED=true" | sudo tee --append /configurationProgress.sh

# Store project name as an environment variable
echo "export PROJECT_NAME=$PROJECT_NAME" | sudo tee --append /etc/profile
. /etc/profile

# Download all files from an S3 bucket matching the PROJECT_NAME (if it exists and the AWS credentials have the rights to the bucket)
aws s3 sync s3://$PROJECT_NAME /home/ec2-user/
echo "S3_FILES_DOWNLOADED=true" | sudo tee --append /configurationProgress.sh

# Ensure ownership for all files is set to the default AWS user
sudo chown ec2-user:ec2-user -R /home/ec2-user

echo "VARIABLES_CREDENTIALS_SAVED=true" | sudo tee --append /configurationProgress.sh
