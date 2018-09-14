#! /bin/bash

# Download Jenkins CLI Jar
cd /home/ec2-user
wget http://localhost:8080/jnlpJars/jenkins-cli.jar

# Avoid Jenkins setup wizard
sudo sed -i 's#<installStateName>NEW.*#<installStateName>RUNNING<\/installStateName>#g' /var/lib/jenkins/config.xml
echo "BYPASS_WIZARD=true" | sudo tee --append /configurationProgress.sh

# Install necessary Jenkins plugins (these plugins have dependencies which get downloaded and installed as well)
JENKINS_PASSWORD=$(./printJenkinsPassword.sh)
java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:$JENKINS_PASSWORD install-plugin git
java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:$JENKINS_PASSWORD install-plugin github
echo "INSTALL_PLUGINS=true" | sudo tee --append /configurationProgress.sh

# Restart Jenkins to complete the installation of the plugins, then ensure Jenkins is up before continuing
sudo service jenkins restart
sleep 70
echo "RESTART_JENKINS=true" | sudo tee --append /configurationProgress.sh

# Create native Jenkins job template XML files from jobs.json and use the new XML file to create a Jenkins job
JOB_COUNT=$(cat jobs.json | jq '.jobs | length')
for (( JOB_INDEX=0; JOB_INDEX<$JOB_COUNT; JOB_INDEX++)); do
  JOB_NAME=$(sed -e 's/^"//' -e 's/"$//' <<< $(cat jobs.json | jq '.jobs['"$JOB_INDEX"'].name'))
  touch $JOB_NAME.xml
  echo "<?xml version='1.1' encoding='UTF-8'?>" | sudo tee --append $JOB_NAME.xml
  echo "<project>" | sudo tee --append $JOB_NAME.xml
  echo "<actions/>" | sudo tee --append $JOB_NAME.xml
  JOB_DESCRIPTION=$(sed -e 's/^"//' -e 's/"$//' <<< $(cat jobs.json | jq '.jobs['"$JOB_INDEX"'].description'))
  if [ "$JOB_DESCRIPTION" != "null" ]; then
    echo "<description>$JOB_DESCRIPTION</description>" | sudo tee --append $JOB_NAME.xml
  else
    echo "<description/>" | sudo tee --append $JOB_NAME.xml
  fi
  echo "<keepDependencies>false</keepDependencies>" | sudo tee --append $JOB_NAME.xml
  echo "<properties/>" | sudo tee --append $JOB_NAME.xml
  echo "<scm class=\"hudson.plugins.git.GitSCM\" plugin=\"git@3.9.1\">" | sudo tee --append $JOB_NAME.xml
  echo "<configVersion>2</configVersion>" | sudo tee --append $JOB_NAME.xml
  echo "<userRemoteConfigs>" | sudo tee --append $JOB_NAME.xml
  echo "<hudson.plugins.git.UserRemoteConfig>" | sudo tee --append $JOB_NAME.xml
  JOB_GIT_URL=$(sed -e 's/^"//' -e 's/"$//' <<< $(cat jobs.json | jq '.jobs['"$JOB_INDEX"'].git.url'))
  echo "<url>$JOB_GIT_URL</url>" | sudo tee --append $JOB_NAME.xml
  JOB_GIT_USERNAME=$(sed -e 's/^"//' -e 's/"$//' <<< $(cat jobs.json | jq '.jobs['"$JOB_INDEX"'].git.credentials.username'))
  JOB_GIT_PASSWORD=$(sed -e 's/^"//' -e 's/"$//' <<< $(cat jobs.json | jq '.jobs['"$JOB_INDEX"'].git.credentials.password'))
  if [ "$JOB_GIT_USERNAME" != "null" ] || [ "$JOB_GIT_PASSWORD" != "null" ]; then
    touch newCredentials.xml
    sudo chmod 755 newCredentials.xml
    echo "<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>" | sudo tee --append newCredentials.xml
    echo "<scope>GLOBAL</scope>" | sudo tee --append newCredentials.xml
    echo "<id>$JOB_GIT_USERNAME</id>" | sudo tee --append newCredentials.xml
    echo "<description></description>" | sudo tee --append newCredentials.xml
    echo "<username>$JOB_GIT_USERNAME</username>" | sudo tee --append newCredentials.xml
    echo "<password>$JOB_GIT_PASSWORD</password>" | sudo tee --append newCredentials.xml
    echo "</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>" | sudo tee --append newCredentials.xml
    java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:$JENKINS_PASSWORD create-credentials-by-xml system::system::jenkins '(global)' < newCredentials.xml
    rm newCredentials.xml
    echo "<credentialsId>$JOB_GIT_USERNAME</credentialsId>" | sudo tee --append $JOB_NAME.xml
  fi
  echo "</hudson.plugins.git.UserRemoteConfig>" | sudo tee --append $JOB_NAME.xml
  echo "</userRemoteConfigs>" | sudo tee --append $JOB_NAME.xml
  echo "<branches>" | sudo tee --append $JOB_NAME.xml
  echo "<hudson.plugins.git.BranchSpec>" | sudo tee --append $JOB_NAME.xml
  JOB_GIT_TRIGGER=$(sed -e 's/^"//' -e 's/"$//' <<< $(cat jobs.json | jq '.jobs['"$JOB_INDEX"'].git.trigger[0]'))
  echo "<name>$JOB_GIT_TRIGGER</name>" | sudo tee --append $JOB_NAME.xml
  echo "</hudson.plugins.git.BranchSpec>" | sudo tee --append $JOB_NAME.xml
  echo "</branches>" | sudo tee --append $JOB_NAME.xml
  echo "<doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>" | sudo tee --append $JOB_NAME.xml
  echo "<submoduleCfg class=\"list\"/>" | sudo tee --append $JOB_NAME.xml
  echo "<extensions/>" | sudo tee --append $JOB_NAME.xml
  echo "</scm>" | sudo tee --append $JOB_NAME.xml
  echo "<canRoam>true</canRoam>" | sudo tee --append $JOB_NAME.xml
  JOB_ENABLED=$(sed -e 's/^"//' -e 's/"$//' <<< $(cat jobs.json | jq '.jobs['"$JOB_INDEX"'].enabled'))
  if [ "$JOB_ENABLED" == "true" ]; then
    echo "<disabled>false</disabled>" | sudo tee --append $JOB_NAME.xml
  else
    echo "<disabled>true</disabled>" | sudo tee --append $JOB_NAME.xml
  fi
  echo "<blockBuildWhenDownstreamBuilding>false</blockBuildWhenDownstreamBuilding>" | sudo tee --append $JOB_NAME.xml
  echo "<blockBuildWhenUpstreamBuilding>false</blockBuildWhenUpstreamBuilding>" | sudo tee --append $JOB_NAME.xml
  echo "<triggers>" | sudo tee --append $JOB_NAME.xml
  echo "<com.cloudbees.jenkins.GitHubPushTrigger plugin=\"github@1.29.2\">" | sudo tee --append $JOB_NAME.xml
  echo "<spec></spec>" | sudo tee --append $JOB_NAME.xml
  echo "</com.cloudbees.jenkins.GitHubPushTrigger>" | sudo tee --append $JOB_NAME.xml
  echo "</triggers>" | sudo tee --append $JOB_NAME.xml
  JOB_BUILD_CONCURRENTLY=$(sed -e 's/^"//' -e 's/"$//' <<< $(cat jobs.json | jq '.jobs['"$JOB_INDEX"'].build.concurrently'))
  echo "<concurrentBuild>$JOB_BUILD_CONCURRENTLY</concurrentBuild>" | sudo tee --append $JOB_NAME.xml
  echo "<builders>" | sudo tee --append $JOB_NAME.xml
  echo "<hudson.tasks.Shell>" | sudo tee --append $JOB_NAME.xml
  echo "<command>" | sudo tee --append $JOB_NAME.xml
  JOB_BUILD_STEP_COUNT=$(cat jobs.json | jq '.jobs['"$JOB_INDEX"'].build.steps | length')
  for (( i=0; i<$JOB_BUILD_STEP_COUNT; i++)); do
    JOB_BUILD_STEP=$(sed -e 's/^"//' -e 's/"$//' -e 's/\\"/"/g' <<< $(cat jobs.json | jq '.jobs['"$JOB_INDEX"'].build.steps['"$i"']'))
    echo $(echo $JOB_BUILD_STEP | recode ascii..html) | sudo tee --append $JOB_NAME.xml
  done
  echo "</command>" | sudo tee --append $JOB_NAME.xml
  echo "</hudson.tasks.Shell>" | sudo tee --append $JOB_NAME.xml
  echo "</builders>" | sudo tee --append $JOB_NAME.xml
  echo "<publishers/>" | sudo tee --append $JOB_NAME.xml
  echo "<buildWrappers/>" | sudo tee --append $JOB_NAME.xml
  echo "</project>" | sudo tee --append $JOB_NAME.xml
  java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:$JENKINS_PASSWORD create-job $JOB_NAME < $JOB_NAME.xml
  rm $JOB_NAME.xml
done
echo "CREATE_JOBS=true" | sudo tee --append /configurationProgress.sh

echo "JENKINS_CONFIGURED=true" | sudo tee --append /configurationProgress.sh
