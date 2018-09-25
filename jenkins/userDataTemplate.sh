# Download scripts to configure Jenkins
cd /home/ec2-user
wget https://s3.us-east-2.amazonaws.com/jenkins-bootstrapper/saveVariablesCredentials.sh
wget https://s3.us-east-2.amazonaws.com/jenkins-bootstrapper/installPackages.sh
wget https://s3.us-east-2.amazonaws.com/jenkins-bootstrapper/configureJenkins.sh
wget https://s3.us-east-2.amazonaws.com/jenkins-bootstrapper/configureNetworking.sh
wget https://s3.us-east-2.amazonaws.com/jenkins-bootstrapper/configureSsl.sh
wget https://s3.us-east-2.amazonaws.com/jenkins-bootstrapper/configureGitHubWebhooks.sh
wget https://s3.us-east-2.amazonaws.com/jenkins-bootstrapper/configureSlaves.sh
wget https://s3.us-east-2.amazonaws.com/jenkins-bootstrapper/printJenkinsPassword.sh
sudo chmod 755 saveVariablesCredentials.sh installPackages.sh configureJenkins.sh configureNetworking.sh configureSlaves.sh configureSsl.sh configureGitHubWebhooks.sh printJenkinsPassword.sh

# Run scripts to configure Jenkins
./saveVariablesCredentials.sh $PROJECT_NAME "$JOBS"
./installPackages.sh
./configureJenkins.sh $PROJECT_NAME
./configureNetworking.sh $PROJECT_NAME $HOSTED_ZONE_NAME
if [ "$CONFIGURE_SSL" == "true" ]; then
  ./configureSsl.sh $HOSTED_ZONE_NAME &
else
  echo "SSL_CONFIGURED=false" | sudo tee --append /configurationProgress.sh
fi
if [ "$CONFIGURE_WEBHOOKS" == "true" ]; then
  ./configureGitHubWebhooks.sh $HOSTED_ZONE_NAME
else
  echo "GITHUB_WEBHOOKS_CONFIGURED=false" | sudo tee --append /configurationProgress.sh
fi
if [ "$CONFIGURE_SLAVES" == "true" ]; then
  ./configureSlaves.sh $PROJECT_NAME $SLAVE_MIN
else
  echo "SLAVES_CONFIGURED=false" | sudo tee --append /configurationProgress.sh
fi

# Restart services
sudo service jenkins restart
sudo service nginx restart

# Delete files
rm saveVariablesCredentials.sh installPackages.sh configureJenkins.sh configureNetworking.sh configureSlaves.sh configureSsl.sh configureGitHubWebhooks.sh
