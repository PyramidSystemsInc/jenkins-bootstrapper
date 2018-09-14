# Jenkins Bootstrapper

### About

Creates an AWS EC2 instance running Jenkins and several ECS clusters configured to run build jobs, run tests, and provide reports all by running a single script (**in progress**)

### Features / TODO

- [ ] Creates an EC2 instance running Jenkins and some ECS clusters (for Selenium, SonarQube, and Jenkins slaves) with a single script
- [X] Creates an EC2 instance running Jenkins and an ECS clusters (for Selenium) with a single script (this line gets deleted when the line above is completed)
- [X] Creates Jenkins jobs programmatically based on a JSON configuration file
- [X] Installs Jenkins plugins automatically and bypasses the Jenkins startup wizard to make Jenkins usable even before the first login
- [X] Creates necessary credentials in Jenkins from the JSON configuration file to support private Git repositories
- [X] Assigns the Jenkins instance an AWS IAM role in order to keep your AWS credentials safe and customize the AWS permissions given to the Jenkins instance
- [X] Updates the GitHub webhooks for all the projects being built in Jenkins jobs
- [X] Stands up a Selenium grid in ECS, accessible from Jenkins, for distributed test execution
- [ ] Stands up a Sonarqube server in ECS to output clean HTML reports of the health of the application(s) being built by Jenkins
- [ ] Creates an ECS cluster using Service Auto Scaling to create and terminate Jenkins slaves depending on demand ensuring Jenkins never crashes due to overuse
- [ ] Updates or creates records in a Route53 hosted zone provided for Jenkins, Selenium, and SonarQube to access your resources at predictable, readable URLs
- [X] Updates or creates records in a Route53 hosted zone provided for Jenkins and Selenium to access your resources at predictable, readable URLs (this line gets deleted when the line above is completed)
- [X] Allows for tearing down all AWS resources that were deployed using Jenkins Boostrapper with a single script
- [X] Copies files from an S3 bucket matching the project's name to the Jenkins EC2 instance (if it exists)
- [X] Uses NGINX and Certbot/Let's Encrypt to enable SSL
- [X] Features clean output to monitor the configuration process of the Jenkins instance
- [ ] Features a useful "help command" and meaningful error messages
- [ ] Supports various post-build actions (i.e. email confirmation for successful builds)
- [ ] Features a script to create the `jobs.json` configuration file using step-by-step command line input
- [ ] Allows parameterized builds (somehow)

### Prerequisites

* AWS account with credentials that have permissions for the following actions:
    * TODO - Document which permissions the host running `./deploy.sh` needs to have
* [AWS CLI installed](https://docs.aws.amazon.com/cli/latest/userguide/installing.html)
* IAM role you want to give to the Jenkins EC2 instance (see IAM permissions section below)

### Minimal Usage

1. Create a `jobs.json` file using the sample files in this project

2. Create an IAM role in AWS with all the permissions you want Jenkins to have (see IAM permissions section below)

3. Deploy a working Jenkins with the following command:

`./deploy -p <PROJECT_NAME> -j <PATH_TO_JOBS_CONFIGURATION_FILE> -i <EXISTING_AWS_IAM_ROLE_FOR_JENKINS_INSTANCE>`

For example:

`./deploy rispd rispd.pyramidchallenges.com. jenkins_instance`

### All Command-Line Options

* TODO - Document the command-line options found in `./deploy.sh`

### IAM Permissions

* The IAM role cannot be created automatically, otherwise the doors to your AWS account would have to be left wide open
