# Jenkins Bootstrapper

### About

Creates an AWS EC2 instance running Jenkins configured to run build jobs and run tests automatically given a simple JSON configuration file all by running a single script (**in progress**)

### Features

- [X] Creates an EC2 instance running Jenkins with one run of a script
- [X] Copies files from an S3 bucket to the Jenkins EC2 instance to ensure private data stays private
- [X] Creates jobs programmatically based on a JSON config file
- [ ] Creates necessary credentials in Jenkins from JSON configuration file (**in progress**)
- [ ] Detects Jenkins plugins needed and installs them automatically (**in progress**)
- [ ] Stands up a Selenium grid in ECS, setup as Jenkins slaves, for distributed test execution
- [ ] Runs Sonarqube plugin on Jenkins to output clean HTML reports of the health of the application(s) being built by Jenkins
- [ ] Features clean output of the `./deploy.sh` script
- [ ] Features a script to create the `jobs.json` configuration file using command line input

### Prerequisites

* AWS account with credentials
* [AWS CLI installed](https://docs.aws.amazon.com/cli/latest/userguide/installing.html)
* [Pulumi installed](https://pulumi.io/quickstart/install.html)

### Usage

1. Create an S3 bucket named after your `PROJECT_NAME`

2. Create a `jobs.json` file using the sample files in this project

3. Upload your new `jobs.json` file to your S3 bucket

4. Deploy a working Jenkins with the following command:

`./deploy <PROJECT_NAME>`

-OR-

`./deploy <PROJECT_NAME> <AWS_ACCESS_KEY> <AWS_SECRET_KEY>`

For example:

`./deploy rispd`

-OR-

`./deploy sample-project skjdfklsdj 239lassfaskjf993ksjdfk`

5. Add the necessary webhooks to your new Jenkins instance on [GitHub's website](https://github.com/)
