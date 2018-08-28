const pulumi = require('@pulumi/pulumi');
const aws = require('@pulumi/aws');
let config = new pulumi.Config('jenkins');
let projectName = config.require('projectName')
let awsAccessKey = config.require('AWS_ACCESS_KEY_ID');
let awsSecretKey = config.require('AWS_SECRET_ACCESS_KEY');

let startupScript = `
#!/bin/bash

# Set AWS Credentials
export AWS_ACCESS_KEY_ID=${awsAccessKey}
export AWS_SECRET_ACCESS_KEY=${awsSecretKey}

# Install Java 8
sudo yum update -y
sudo yum remove java-1.7.0-openjdk -y
sudo yum install java-1.8.0-openjdk-devel -y

# Install Jenkins
sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key
sudo yum install jenkins -y

# Install Docker
sudo yum install docker -y
sudo service docker start
sudo usermod -aG docker ec2-user
sudo usermod -aG docker jenkins

# Install Git
sudo yum install -y git

# Install C++
sudo yum install gcc-c++ -y

# Install NodeJS 10
curl --silent --location https://rpm.nodesource.com/setup_10.x | sudo bash -
sudo yum install nodejs -y

# Install NGinX
sudo yum install nginx -y

# Install JQ
sudo yum install jq -y

# Install AWS ECS CLI
sudo curl -o /usr/local/bin/ecs-cli https://s3.amazonaws.com/amazon-ecs-cli/ecs-cli-linux-amd64-latest
sudo chmod +x /usr/local/bin/ecs-cli

# Store AWS Credentials for Jenkins
sudo mkdir -p /var/lib/jenkins/.aws
sudo touch /var/lib/jenkins/.aws/credentials
echo "[default]" | sudo tee --append /var/lib/jenkins/.aws/credentials
echo "aws_access_key_id = ${awsAccessKey}" | sudo tee --append /var/lib/jenkins/.aws/credentials
echo "aws_secret_access_key = ${awsSecretKey}" | sudo tee --append /var/lib/jenkins/.aws/credentials

# Store AWS Credentials for ec2-user
sudo mkdir -p /home/ec2-user/.aws
sudo touch /home/ec2-user/.aws/credentials
echo "[default]" | sudo tee --append /home/ec2-user/.aws/credentials
echo "aws_access_key_id = ${awsAccessKey}" | sudo tee --append /home/ec2-user/.aws/credentials
echo "aws_secret_access_key = ${awsSecretKey}" | sudo tee --append /home/ec2-user/.aws/credentials

# Start Jenkins
sudo service jenkins start

# Create script to print the default Jenkins password
touch /home/ec2-user/printJenkinsPassword.sh
echo "#! /bin/bash" | sudo tee --append /home/ec2-user/printJenkinsPassword.sh
echo "" | sudo tee --append /home/ec2-user/printJenkinsPassword.sh
echo "sudo cat /var/lib/jenkins/secrets/initialAdminPassword" | sudo tee --append /home/ec2-user/printJenkinsPassword.sh
sudo chmod 755 /home/ec2-user/printJenkinsPassword.sh

# Download all files from an S3 bucket matching the PROJECT_NAME
aws s3 sync s3://${projectName} /home/ec2-user/

# Download the Jenkins CLI JAR
cd /home/ec2-user
sleep 20
sudo sed -i 's#<installStateName>NEW.*#<installStateName>RUNNING<\/installStateName>#g' /var/lib/jenkins/config.xml
wget http://localhost:8080/jnlpJars/jenkins-cli.jar
JENKINS_PASSWORD=$(./printJenkinsPassword.sh)

# Create Jenkins jobs from jobs.json configuration file
java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:$JENKINS_PASSWORD install-plugin git
java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:$JENKINS_PASSWORD install-plugin github
JOB_INDEX=0
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
echo "<command>ls</command>" | sudo tee --append $JOB_NAME.xml
echo "</hudson.tasks.Shell>" | sudo tee --append $JOB_NAME.xml
echo "</builders>" | sudo tee --append $JOB_NAME.xml
echo "<publishers/>" | sudo tee --append $JOB_NAME.xml
echo "<buildWrappers/>" | sudo tee --append $JOB_NAME.xml
echo "</project>" | sudo tee --append $JOB_NAME.xml
# java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:$JENKINS_PASSWORD create-job my-new-job < template.xml

# Restart services
sudo service jenkins restart
sudo service nginx restart
`;

let size = 't2.medium';
let ami = 'ami-40142d25';
let id = projectName + '-jenkins';

let group = new aws.ec2.SecurityGroup(id, {
  ingress: [
    { protocol: 'tcp', fromPort: 22, toPort: 22, cidrBlocks: ['0.0.0.0/0'] },
    { protocol: 'tcp', fromPort: 80, toPort: 80, cidrBlocks: ['0.0.0.0/0'] },
    { protocol: 'tcp', fromPort: 443, toPort: 443, cidrBlocks: ['0.0.0.0/0'] },
    {
      protocol: 'tcp',
      fromPort: 8080,
      toPort: 8080,
      cidrBlocks: ['0.0.0.0/0']
    },
    {
      protocol: 'tcp',
      fromPort: 8081,
      toPort: 8081,
      cidrBlocks: ['0.0.0.0/0']
    },
    {
      protocol: 'tcp',
      fromPort: 8084,
      toPort: 8084,
      cidrBlocks: ['0.0.0.0/0']
    },
    {
      protocol: 'tcp',
      fromPort: 8123,
      toPort: 8123,
      cidrBlocks: ['0.0.0.0/0']
    },
    {
      protocol: 'tcp',
      fromPort: 8124,
      toPort: 8124,
      cidrBlocks: ['0.0.0.0/0']
    },
    {
      protocol: 'tcp',
      fromPort: 9000,
      toPort: 9000,
      cidrBlocks: ['0.0.0.0/0']
    },
    { protocol: 'tcp', fromPort: 9092, toPort: 9092, cidrBlocks: ['0.0.0.0/0'] }
  ],
  egress: [
    { protocol: '-1', fromPort: 0, toPort: 0, cidrBlocks: ['0.0.0.0/0'] }
  ]
});

let server = new aws.ec2.Instance(id, {
  ami: ami,
  instanceType: size,
  keyName: projectName,
  rootBlockDevice: {
    volumeSize: 16,
    volumeType: 'gp2'
  },
  securityGroups: [group.name],
  tags: {
    Name: id,
    Project: projectName
  },
  userData: startupScript
});

exports.ipAddress = server.publicIp;
exports.publicHostName = server.publicDns;
