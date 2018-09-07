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

# Install Recode
sudo yum install recode -y

# Install AWS ECS CLI
sudo curl -o /usr/local/bin/ecs-cli https://s3.amazonaws.com/amazon-ecs-cli/ecs-cli-linux-amd64-latest
sudo chmod +x /usr/local/bin/ecs-cli

# Store AWS Credentials for root
export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_KEY

# Store AWS Credentials for Jenkins
sudo mkdir -p /var/lib/jenkins/.aws
sudo touch /var/lib/jenkins/.aws/credentials
echo "[default]" | sudo tee --append /var/lib/jenkins/.aws/credentials
echo "aws_access_key_id = $AWS_ACCESS_KEY" | sudo tee --append /var/lib/jenkins/.aws/credentials
echo "aws_secret_access_key = $AWS_SECRET_KEY" | sudo tee --append /var/lib/jenkins/.aws/credentials

# Store AWS Credentials for ec2-user
sudo mkdir -p /home/ec2-user/.aws
sudo touch /home/ec2-user/.aws/credentials
echo "[default]" | sudo tee --append /home/ec2-user/.aws/credentials
echo "aws_access_key_id = $AWS_ACCESS_KEY" | sudo tee --append /home/ec2-user/.aws/credentials
echo "aws_secret_access_key = $AWS_SECRET_KEY" | sudo tee --append /home/ec2-user/.aws/credentials

# Start Jenkins
sudo service jenkins start

# Download all files from an S3 bucket matching the PROJECT_NAME (assumes jobs.json is found in this bucket)
aws s3 sync s3://$PROJECT_NAME /home/ec2-user/

# Ensure Jenkins was started by waiting
cd /home/ec2-user
sleep 30

# Set environment variables
echo "export PROJECT_NAME=$PROJECT_NAME" | sudo tee --append /etc/profile
. /etc/profile

# Configure Jenkins using the Jenkins CLI
wget http://localhost:8080/jnlpJars/jenkins-cli.jar
wget https://s3.us-east-2.amazonaws.com/jenkins-bootstrapper/configureJenkins.sh
wget https://s3.us-east-2.amazonaws.com/jenkins-bootstrapper/configureNetworking.sh
wget https://s3.us-east-2.amazonaws.com/jenkins-bootstrapper/configureSsl.sh
wget https://s3.us-east-2.amazonaws.com/jenkins-bootstrapper/configureGitHubWebhooks.sh
wget https://s3.us-east-2.amazonaws.com/jenkins-bootstrapper/printJenkinsPassword.sh
sudo chmod 755 configureJenkins.sh configureNetworking.sh configureSsl.sh configureGitHubWebhooks.sh printJenkinsPassword.sh
./configureJenkins.sh
./configureNetworking.sh $PROJECT_NAME $HOSTED_ZONE_NAME
#./configureSsl.sh $HOSTED_ZONE_NAME
./configureGitHubWebhooks.sh $HOSTED_ZONE_NAME

# Restart services
sudo service jenkins restart
sudo service nginx restart
