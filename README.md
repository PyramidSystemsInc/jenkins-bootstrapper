# Jenkins Bootstrapper

### About

Creates an AWS EC2 instance running Jenkins configured to build and run tests automatically given a set of Jenkinsfiles all by running a single script (**in progress**)

### Features

- [X] Creates an EC2 instance running Jenkins with one run of a script
- [ ] Creates a pipeline job for each Jenkinsfile in the `jobs/` directory
- [ ] Stands up a Selenium grid in ECS, setup as Jenkins slaves, for distributed test execution
- [ ] Runs Sonarqube plugin on Jenkins to output clean HTML reports of the health of the application(s) being built by Jenkins
- [X] If an S3 bucket exists with the same name on the same AWS account, all of the files in that bucket will be copied to the home directory of the EC2 instance running Jenkins
- [ ] Features clean output of the `./deploy.sh` script

### Prerequisites

* AWS account with credentials
* [AWS CLI installed](https://docs.aws.amazon.com/cli/latest/userguide/installing.html)
* [Pulumi installed](https://pulumi.io/quickstart/install.html)

### Usage

`./deploy <PROJECT_NAME>`

-OR-

`./deploy <PROJECT_NAME> <AWS_ACCESS_KEY> <AWS_SECRET_KEY>`

For example:

`./deploy rispd`

-OR-

`./deploy sample-project skjdfklsdj 239lassfaskjf993ksjdfk`
