# Jenkins Bootstrapper

### About

Creates an AWS EC2 instance running Jenkins configured to run build jobs and run tests automatically given a simple JSON configuration file all by running a single script (**in progress**)

### Features

- [X] Creates an EC2 instance running Jenkins with a single script
- [X] Copies files from an S3 bucket matching the project's name to the Jenkins EC2 instance
- [X] Creates Jenkins jobs programmatically based on a JSON configuration file found in the S3 bucket
- [X] Installs Jenkins plugins automatically and bypasses the Jenkins startup wizard
- [X] Creates necessary credentials in Jenkins from the JSON configuration file
- [X] Stands up a Selenium grid in ECS, accessible from Jenkins, for distributed test execution
- [X] Automatically updates GitHub webhooks for all the projects being built in Jenkins
- [X] Updates or creates records in the Route53 hosted zone provided for Jenkins and Selenium
- [X] Uses NGINX and Certbot/Let's Encrypt to enable SSL
- [ ] Stands up a Sonarqube server in ECS to output clean HTML reports of the health of the application(s) being built by Jenkins
- [ ] Creates the provided Route53 hosted zone if it does not exist
- [ ] Supports various post-build actions (i.e. email confirmation for builds)
- [ ] Features clean output of the `./deploy.sh` script
- [ ] Features a script to create the `jobs.json` configuration file using command line input

### Prerequisites

* AWS account with credentials
* [AWS CLI installed](https://docs.aws.amazon.com/cli/latest/userguide/installing.html)

### Usage

1. Create an S3 bucket named after your `PROJECT_NAME`

2. Create a `jobs.json` file using the sample files in this project

3. Upload your new `jobs.json` file to your S3 bucket

4. Ensure a hosted zone is created in Route53

4. Deploy a working Jenkins with the following command:

`./deploy <PROJECT_NAME> <EXISTING_AWS_HOSTED_ZONE_NAME>`

-OR-

`./deploy <PROJECT_NAME> <EXISTING_AWS_HOSTED_ZONE_NAME> <AWS_ACCESS_KEY> <AWS_SECRET_KEY>`

For example:

`./deploy rispd rispd.pyramidchallenges.com.`

-OR-

`./deploy sample-project project.sample.com. skjdfklsdj 239lassfaskjf993ksjdfk`
