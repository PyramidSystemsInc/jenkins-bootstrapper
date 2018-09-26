# Download scripts to configure Jenkins
cd /home/ec2-user

# Wait for configuration scripts to be secure copied over
while : ; do
  if [ ! -f /home/ec2-user/copyFiles.sh ]; then
    sleep 2
  else
    break
  fi
done

sudo chmod 755 copyFiles.sh installPackages.sh configureJenkins.sh configureNetworking.sh configureSlaves.sh configureSsl.sh configureGitHubWebhooks.sh printJenkinsPassword.sh

# Run scripts to configure Jenkins
./copyFiles.sh $PROJECT_NAME "$JOBS"
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
rm copyFiles.sh installPackages.sh configureJenkins.sh configureNetworking.sh configureSlaves.sh configureSsl.sh configureGitHubWebhooks.sh
