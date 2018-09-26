#! /bin/bash

# Define all colors used for output
function defineColorPalette() {
	COLOR_RED_BOLD='\033[1;91m'
	COLOR_GREEN_BOLD='\033[1;32m'
	COLOR_BLUE_BOLD='\033[1;34m'
	COLOR_WHITE_BOLD='\033[1;97m'
	COLOR_NONE='\033[0m'
}

# Define special characters
function defineSpecialCharacters() {
	CHECK_MARK='\xE2\x9C\x94'
}

# Show output for copyFiles.sh script
function monitorCopyFilesProgress() {
	echo -e ""
	ELLIPSIS=""
	LINE_COUNT=4
	for (( LINE_INDEX=0; LINE_INDEX<LINE_COUNT; LINE_INDEX++ )) do
		echo -e ""
	done
	while : ; do
		. /configurationProgress.sh
		ELLIPSIS+="."
		echo -en "\e[${LINE_COUNT}A"
		if [ -n "$VARIABLES_CREDENTIALS_SAVED" ]; then
			if [ "$VARIABLES_CREDENTIALS_SAVED" == true ]; then
			echo -e "${COLOR_GREEN_BOLD}[ ${CHECK_MARK} DONE ]${COLOR_WHITE_BOLD} (1/6) Saving new files to EC2 instance          "
			elif [ "$VARIABLES_CREDENTIALS_SAVED" == "false" ]; then
				echo -e "${COLOR_RED_BOLD}[ SKIPPED ]${COLOR_WHITE_BOLD} (1/6) Saving new files to EC2 instance           "
			fi
		else
			if [ ${#ELLIPSIS} -gt 3 ]; then
				echo -e "${COLOR_BLUE_BOLD}[ IN PROGRESS ]${COLOR_WHITE_BOLD} (1/6) Saving new files to EC2 instance   "
				ELLIPSIS=""
			else
				echo -e "${COLOR_BLUE_BOLD}[ IN PROGRESS ]${COLOR_WHITE_BOLD} (1/6) Saving new files to EC2 instance$ELLIPSIS"
			fi
		fi
		echo -e "    ${COLOR_NONE}- [$([ -n "$CONFIG_PROGRESS_CREATED" ] && "$CONFIG_PROGRESS_CREATED" == "true" && echo "X" || echo " ")] Creating file to monitor instance configuring process"
		echo -e "    ${COLOR_NONE}- [$([ -n "$JOBS_JSON_CREATED" ] && "$JOBS_JSON_CREATED" == "true" && echo "X" || echo " ")] Creating jobs.json file"
		echo -e "    ${COLOR_NONE}- [$([ -n "$S3_FILES_DOWNLOADED" ] && "$S3_FILES_DOWNLOADED" == "true" && echo "X" || echo " ")] Downloading files from S3 bucket matching the project name (if it exists)"
		sleep 0.75
		[[ -z "$VARIABLES_CREDENTIALS_SAVED" ]] || break
	done
}

# Show output for configureGitHubWebhooks.sh script
function monitorConfigureGitHubWebhooksProgress() {
	echo -e ""
	ELLIPSIS=""
	LINE_COUNT=3
	for (( LINE_INDEX=0; LINE_INDEX<LINE_COUNT; LINE_INDEX++ )) do
		echo -e ""
	done
	while : ; do
		. /configurationProgress.sh
		ELLIPSIS+="."
		echo -en "\e[${LINE_COUNT}A"
		if [ -n "$GITHUB_WEBHOOKS_CONFIGURED" ]; then
			if [ "$GITHUB_WEBHOOKS_CONFIGURED" == true ]; then
				echo -e "${COLOR_GREEN_BOLD}[ ${CHECK_MARK} DONE ]${COLOR_WHITE_BOLD} (6/6) Configuring GitHub Webhooks          "
			elif [ "$GITHUB_WEBHOOKS_CONFIGURED" == "false" ]; then
				echo -e "${COLOR_RED_BOLD}[ SKIPPED ]${COLOR_WHITE_BOLD} (6/6) Configuring GitHub Webhooks          "
			fi
		else
			if [ ${#ELLIPSIS} -gt 3 ]; then
				echo -e "${COLOR_BLUE_BOLD}[ IN PROGRESS ]${COLOR_WHITE_BOLD} (6/6) Configuring GitHub Webhooks   "
				ELLIPSIS=""
			else
				echo -e "${COLOR_BLUE_BOLD}[ IN PROGRESS ]${COLOR_WHITE_BOLD} (6/6) Configuring GitHub Webhooks$ELLIPSIS"
			fi
		fi
		echo -e "    ${COLOR_NONE}- [$([ -n "$CREATE_PAYLOAD" ] && "$CREATE_PAYLOAD" == "true" && echo "X" || echo " ")] Creating payload to be sent to api.github.com"
		echo -e "    ${COLOR_NONE}- [$([ -n "$CREATE_WEBHOOKS" ] && "$CREATE_WEBHOOKS" == "true" && echo "X" || echo " ")] Creating a webhook for each unique Git project in the jobs.json file"
		sleep 0.75
		[[ -z "$GITHUB_WEBHOOKS_CONFIGURED" ]] || break
	done
}

# Show output for configureJenkins.sh script
function monitorConfigureJenkinsProgress() {
	echo -e ""
	ELLIPSIS=""
	LINE_COUNT=5
	for (( LINE_INDEX=0; LINE_INDEX<LINE_COUNT; LINE_INDEX++ )) do
		echo -e ""
	done
	while : ; do
		. /configurationProgress.sh
		ELLIPSIS+="."
		echo -en "\e[${LINE_COUNT}A"
		if [ -n "$JENKINS_CONFIGURED" ]; then
			if [ "$JENKINS_CONFIGURED" == true ]; then
				echo -e "${COLOR_GREEN_BOLD}[ ${CHECK_MARK} DONE ]${COLOR_WHITE_BOLD} (3/6) Configuring Jenkins          "
			elif [ "$JENKINS_CONFIGURED" == "false" ]; then
				echo -e "${COLOR_RED_BOLD}[ SKIPPED ]${COLOR_WHITE_BOLD} (3/6) Configuring Jenkins          "
			fi
		else
			if [ ${#ELLIPSIS} -gt 3 ]; then
				echo -e "${COLOR_BLUE_BOLD}[ IN PROGRESS ]${COLOR_WHITE_BOLD} (3/6) Configuring Jenkins   "
				ELLIPSIS=""
			else
				echo -e "${COLOR_BLUE_BOLD}[ IN PROGRESS ]${COLOR_WHITE_BOLD} (3/6) Configuring Jenkins$ELLIPSIS"
			fi
		fi
		echo -e "    ${COLOR_NONE}- [$([ -n "$BYPASS_WIZARD" ] && "$BYPASS_WIZARD" == "true" && echo "X" || echo " ")] Bypassing Jenkins setup wizard"
		echo -e "    ${COLOR_NONE}- [$([ -n "$INSTALL_PLUGINS" ] && "$INSTALL_PLUGINS" == "true" && echo "X" || echo " ")] Installing necessary plugins"
		echo -e "    ${COLOR_NONE}- [$([ -n "$RESTART_JENKINS" ] && "$RESTART_JENKINS" == "true" && echo "X" || echo " ")] Restarting Jenkins"
		echo -e "    ${COLOR_NONE}- [$([ -n "$CREATE_JOBS" ] && "$CREATE_JOBS" == "true" && echo "X" || echo " ")] Creating jobs"
		sleep 0.75
		[[ -z "$JENKINS_CONFIGURED" ]] || break
	done
}

# Show output for configureNetworking.sh script
function monitorConfigureNetworkingProgress() {
	echo -e ""
	ELLIPSIS=""
	LINE_COUNT=5
	for (( LINE_INDEX=0; LINE_INDEX<LINE_COUNT; LINE_INDEX++ )) do
		echo -e ""
	done
	while : ; do
		. /configurationProgress.sh
		ELLIPSIS+="."
		echo -en "\e[${LINE_COUNT}A"
		if [ -n "$NETWORKING_CONFIGURED" ]; then
			if [ "$NETWORKING_CONFIGURED" == true ]; then
				echo -e "${COLOR_GREEN_BOLD}[ ${CHECK_MARK} DONE ]${COLOR_WHITE_BOLD} (4/6) Configuring Networking          "
			elif [ "$NETWORKING_CONFIGURED" == "false" ]; then
				echo -e "${COLOR_RED_BOLD}[ SKIPPED ]${COLOR_WHITE_BOLD} (4/6) Configuring Networking          "
			fi
		else
			if [ ${#ELLIPSIS} -gt 3 ]; then
				echo -e "${COLOR_BLUE_BOLD}[ IN PROGRESS ]${COLOR_WHITE_BOLD} (4/6) Configuring Networking   "
				ELLIPSIS=""
			else
				echo -e "${COLOR_BLUE_BOLD}[ IN PROGRESS ]${COLOR_WHITE_BOLD} (4/6) Configuring Networking$ELLIPSIS"
			fi
		fi
		echo -e "    ${COLOR_NONE}- [$([ -n "$ADD_SELENIUM_TO_HOSTS" ] && "$ADD_SELENIUM_TO_HOSTS" == "true" && echo "X" || echo " ")] Adding Selenium to hosts"
		echo -e "    ${COLOR_NONE}- [$([ -n "$FIND_HOSTED_ZONE_ID" ] && "$FIND_HOSTED_ZONE_ID" == "true" && echo "X" || echo " ")] Finding the corresponding ID to the hosted zone name provided"
		echo -e "    ${COLOR_NONE}- [$([ -n "$CREATE_JENKINS_RECORD" ] && "$CREATE_JENKINS_RECORD" == "true" && echo "X" || echo " ")] Creating/updating the record for jenkins.<HOSTED_ZONE>"
		echo -e "    ${COLOR_NONE}- [$([ -n "$CREATE_SELENIUM_RECORD" ] && "$CREATE_SELENIUM_RECORD" == "true" && echo "X" || echo " ")] Creating/updating the record for selenium.<HOSTED_ZONE>"
		sleep 0.75
		[[ -z "$NETWORKING_CONFIGURED" ]] || break
	done
}

# Show output for configureSsl.sh script
function monitorConfigureSslProgress() {
	echo -e ""
	ELLIPSIS=""
	LINE_COUNT=4
	for (( LINE_INDEX=0; LINE_INDEX<LINE_COUNT; LINE_INDEX++ )) do
		echo -e ""
	done
	while : ; do
		. /configurationProgress.sh
		ELLIPSIS+="."
		echo -en "\e[${LINE_COUNT}A"
		if [ -n "$SSL_CONFIGURED" ]; then
			if [ "$SSL_CONFIGURED" == true ]; then
				echo -e "${COLOR_GREEN_BOLD}[ ${CHECK_MARK} DONE ]${COLOR_WHITE_BOLD} (5/6) Configuring SSL          "
			elif [ "$SSL_CONFIGURED" == "false" ]; then
				echo -e "${COLOR_RED_BOLD}[ SKIPPED ]${COLOR_WHITE_BOLD} (5/6) Configuring SSL          "
			fi
		else
			if [ ${#ELLIPSIS} -gt 3 ]; then
				echo -e "${COLOR_BLUE_BOLD}[ IN PROGRESS ]${COLOR_WHITE_BOLD} (5/6) Configuring SSL   "
				ELLIPSIS=""
			else
				echo -e "${COLOR_BLUE_BOLD}[ IN PROGRESS ]${COLOR_WHITE_BOLD} (5/6) Configuring SSL$ELLIPSIS"
			fi
		fi
		echo -e "    ${COLOR_NONE}- [$([ -n "$DOWNLOAD_CERTBOT" ] && "$DOWNLOAD_CERTBOT" == "true" && echo "X" || echo " ")] Downloading Certbot"
		echo -e "    ${COLOR_NONE}- [$([ -n "$GET_CERTS" ] && "$GET_CERTS" == "true" && echo "X" || echo " ")] Getting Certificates through Let's Encrypt"
		echo -e "    ${COLOR_NONE}- [$([ -n "$REPLACE_NGINX_CONFIG" ] && "$REPLACE_NGINX_CONFIG" == "true" && echo "X" || echo " ")] Replacing the NGINX configuration file"
		sleep 0.75
		[[ -z "$SSL_CONFIGURED" ]] || break
	done
}

# Show output for installPackages.sh script
function monitorInstallPackagesProgress() {
	echo -e ""
	ELLIPSIS=""
	LINE_COUNT=13
	for (( LINE_INDEX=0; LINE_INDEX<LINE_COUNT; LINE_INDEX++ )) do
		echo -e ""
	done
	while : ; do
		. /configurationProgress.sh
		ELLIPSIS+="."
		echo -en "\e[${LINE_COUNT}A"
		if [ -n "$PACKAGES_INSTALLED" ]; then
			if [ "$PACKAGES_INSTALLED" == true ]; then
				echo -e "${COLOR_GREEN_BOLD}[ ${CHECK_MARK} DONE ]${COLOR_WHITE_BOLD} (2/6) Installing packages          "
			elif [ "$PACKAGES_INSTALLED" == "false" ]; then
				echo -e "${COLOR_RED_BOLD}[ SKIPPED ]${COLOR_WHITE_BOLD} (2/6) Installing packages          "
			fi
		else
			if [ ${#ELLIPSIS} -gt 3 ]; then
				echo -e "${COLOR_BLUE_BOLD}[ IN PROGRESS ]${COLOR_WHITE_BOLD} (2/6) Installing packages   "
				ELLIPSIS=""
			else
				echo -e "${COLOR_BLUE_BOLD}[ IN PROGRESS ]${COLOR_WHITE_BOLD} (2/6) Installing packages$ELLIPSIS"
			fi
		fi
		echo -e "    ${COLOR_NONE}- [$([ -n "$PERFORM_YUM_UPDATE" ] && "$PERFORM_YUM_UPDATE" == "true" && echo "X" || echo " ")] Updating available packages"
		echo -e "    ${COLOR_NONE}- [$([ -n "$INSTALL_JAVA" ] && "$INSTALL_JAVA" == "true" && echo "X" || echo " ")] Installing Java 8"
		echo -e "    ${COLOR_NONE}- [$([ -n "$INSTALL_JENKINS" ] && "$INSTALL_JENKINS" == "true" && echo "X" || echo " ")] Installing Jenkins"
		echo -e "    ${COLOR_NONE}- [$([ -n "$INSTALL_DOCKER" ] && "$INSTALL_DOCKER" == "true" && echo "X" || echo " ")] Installing Docker"
		echo -e "    ${COLOR_NONE}- [$([ -n "$INSTALL_GIT" ] && "$INSTALL_GIT" == "true" && echo "X" || echo " ")] Installing Git"
		echo -e "    ${COLOR_NONE}- [$([ -n "$INSTALL_CPP" ] && "$INSTALL_CPP" == "true" && echo "X" || echo " ")] Installing C++"
		echo -e "    ${COLOR_NONE}- [$([ -n "$INSTALL_NODEJS" ] && "$INSTALL_NODEJS" == "true" && echo "X" || echo " ")] Installing NodeJS"
		echo -e "    ${COLOR_NONE}- [$([ -n "$INSTALL_NGINX" ] && "$INSTALL_NGINX" == "true" && echo "X" || echo " ")] Installing NGINX"
		echo -e "    ${COLOR_NONE}- [$([ -n "$INSTALL_JQ" ] && "$INSTALL_JQ" == "true" && echo "X" || echo " ")] Installing JQ"
		echo -e "    ${COLOR_NONE}- [$([ -n "$INSTALL_RECODE" ] && "$INSTALL_RECODE" == "true" && echo "X" || echo " ")] Installing Recode"
		echo -e "    ${COLOR_NONE}- [$([ -n "$INSTALL_AWS_ECS_CLI" ] && "$INSTALL_AWS_ECS_CLI" == "true" && echo "X" || echo " ")] Installing the AWS ECS CLI"
		echo -e "    ${COLOR_NONE}- [$([ -n "$START_JENKINS" ] && "$START_JENKINS" == "true" && echo "X" || echo " ")] Starting Jenkins"
		sleep 0.75
		[[ -z "$PACKAGES_INSTALLED" ]] || break
	done
}

defineColorPalette
defineSpecialCharacters
monitorCopyFilesProgress
monitorInstallPackagesProgress
monitorConfigureJenkinsProgress
monitorConfigureNetworkingProgress
monitorConfigureSslProgress
monitorConfigureGitHubWebhooksProgress
echo -e ""
