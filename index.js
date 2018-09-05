const pulumi = require('@pulumi/pulumi');
const aws = require('@pulumi/aws');
let config = new pulumi.Config('jenkins');
let projectName = config.require('projectName')
let hostedZoneName = config.require('hostedZoneName')
let awsAccessKey = config.require('AWS_ACCESS_KEY_ID');
let awsSecretKey = config.require('AWS_SECRET_ACCESS_KEY');

let startupScript = `
#!/bin/bash

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

# Install JQ
sudo yum install recode -y

# Install AWS ECS CLI
sudo curl -o /usr/local/bin/ecs-cli https://s3.amazonaws.com/amazon-ecs-cli/ecs-cli-linux-amd64-latest
sudo chmod +x /usr/local/bin/ecs-cli

# Store AWS Credentials for root
export AWS_ACCESS_KEY_ID=${awsAccessKey}
export AWS_SECRET_ACCESS_KEY=${awsSecretKey}

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

# Download all files from an S3 bucket matching the PROJECT_NAME (assumes jobs.json is found in this bucket)
aws s3 sync s3://${projectName} /home/ec2-user/

# Ensure Jenkins was started by waiting
cd /home/ec2-user
sleep 30

# Set environment variables
echo "export PROJECT_NAME=${projectName}" | sudo tee --append /etc/profile
. /etc/profile

# Configure Jenkins using the Jenkins CLI
wget http://localhost:8080/jnlpJars/jenkins-cli.jar
wget https://s3.us-east-2.amazonaws.com/jenkins-bootstrapper/configureJenkins.sh
wget https://s3.us-east-2.amazonaws.com/jenkins-bootstrapper/configureNetworking.sh
wget https://s3.us-east-2.amazonaws.com/jenkins-bootstrapper/configureSsl.sh
wget https://s3.us-east-2.amazonaws.com/jenkins-bootstrapper/printJenkinsPassword.sh
sudo chmod 755 configureJenkins.sh configureNetworking.sh configureSsl.sh printJenkinsPassword.sh
./configureJenkins.sh
./configureNetworking.sh ${projectName} ${hostedZoneName}
./configureSsl.sh ${hostedZoneName}

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
  keyName: projectName + '-jenkins',
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
