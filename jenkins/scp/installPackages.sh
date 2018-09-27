#! /bin/bash

# Install AWS ECS CLI
function installAwsEcsCli() {
  sudo curl -o /usr/local/bin/ecs-cli https://s3.amazonaws.com/amazon-ecs-cli/ecs-cli-linux-amd64-latest
  sudo chmod +x /usr/local/bin/ecs-cli
  echo "INSTALL_AWS_ECS_CLI=true" | sudo tee --append /configurationProgress.sh
}

# Install C++
function installCpp() {
  sudo yum install gcc-c++ -y
  echo "INSTALL_CPP=true" | sudo tee --append /configurationProgress.sh
}

# Install Docker
function installDocker() {
  sudo yum install docker -y
  sudo service docker start
  sudo usermod -aG docker ec2-user
  sudo usermod -aG docker jenkins
  echo "INSTALL_DOCKER=true" | sudo tee --append /configurationProgress.sh
}

# Install Git
function installGit() {
  sudo yum install -y git
  echo "INSTALL_GIT=true" | sudo tee --append /configurationProgress.sh
}

# Install Java 8
function installJava() {
  sudo yum remove java-1.7.0-openjdk -y
  sudo yum install java-1.8.0-openjdk-devel -y
  echo "INSTALL_JAVA=true" | sudo tee --append /configurationProgress.sh
}

# Install Jenkins
function installJenkins() {
  sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
  sudo rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key
  sudo yum install jenkins -y
  echo "INSTALL_JENKINS=true" | sudo tee --append /configurationProgress.sh
}

# Install JQ
function installJq() {
  sudo yum install jq -y
  echo "INSTALL_JQ=true" | sudo tee --append /configurationProgress.sh
}

# Install NGinX
function installNginx() {
  sudo yum install nginx -y
  echo "INSTALL_NGINX=true" | sudo tee --append /configurationProgress.sh
}

# Install NodeJS 10
function installNodeJs() {
  curl --silent --location https://rpm.nodesource.com/setup_10.x | sudo bash -
  sudo yum install nodejs -y
  echo "INSTALL_NODEJS=true" | sudo tee --append /configurationProgress.sh
}

# Install Recode
function installRecode() {
  sudo yum install recode -y
  echo "INSTALL_RECODE=true" | sudo tee --append /configurationProgress.sh
}

# Update available packages
function performYumUpdate() {
  sudo yum update -y
  echo "PERFORM_YUM_UPDATE=true" | sudo tee --append /configurationProgress.sh
}

# Record this script finished successfully
function recordSuccessfulRun() {
  echo "PACKAGES_INSTALLED=true" | sudo tee --append /configurationProgress.sh
}

# Start Jenkins (ensure Jenkins is up before running the next command by waiting)
function startJenkins() {
  sudo service jenkins start
  cd /home/ec2-user
  sleep 30
  echo "START_JENKINS=true" | sudo tee --append /configurationProgress.sh
}

performYumUpdate
installJava
installJenkins
installDocker
installGit
installCpp
installNodeJs
installNginx
installJq
installRecode
installAwsEcsCli
startJenkins
recordSuccessfulRun
