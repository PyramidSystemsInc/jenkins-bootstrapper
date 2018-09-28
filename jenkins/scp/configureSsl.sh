#! /bin/bash

# Download Certbot
function downloadCertbot() {
  cd /home/ec2-user
  wget https://dl.eff.org/certbot-auto
  chmod a+x certbot-auto
  echo "DOWNLOAD_CERTBOT=true" | sudo tee --append /configurationProgress.sh
}

# Ensure a hosted zone name is provided
function ensureHostedZoneProvided() {
  if [ -z "$1" ]; then
    echo -e "${COLOR_RED}ERROR: Hosted zone name must be provided. Please re-run as follows:${COLOR_NONE}"
    echo -e "${COLOR_WHITE}    ./configureSsl.sh <HOSTED_ZONE_NAME>"
    echo -e "${COLOR_NONE}"
    exit 2
  else
    HOSTED_ZONE_NAME=$1
  fi
}

# TODO Create a CRON job to renew certificates every 56 days
# Get certificates from Certbot (valid for 60 days)
function getCertificates() {
  sudo ./certbot-auto --nginx --debug -n --agree-tos --email jdiederiks@psi-it.com --domains $DOMAIN
  echo "GET_CERTS=true" | sudo tee --append /configurationProgress.sh
}

# Replace NGINX config file
function replaceNginxConfiguration() {
  sudo rm /etc/nginx/nginx.conf
  sudo mkdir -p /etc/nginx/
  sudo touch /etc/nginx/nginx.conf
	cat <<- EOF > /etc/nginx/nginx.conf
		user nginx;
		worker_processes auto;
		error_log /var/log/nginx/error.log;
		pid /var/run/nginx.pid;
		
		include /usr/share/nginx/modules/*.conf;
		
		events {
		  worker_connections 1024;
		}
		
		http {
		  proxy_send_timeout  120;
		  proxy_read_timeout  300;
		  proxy_buffering     off;
		  keepalive_timeout   5 5;
		  tcp_nodelay         on;
		
		  server {
		    listen  *:443;
		    server_name  $DOMAIN;
		
		    client_max_body_size 1G;
		
		    ssl on;
		    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
		    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
		
		    location / {
		      proxy_pass http://localhost:8080/;
		      proxy_set_header Host \$host;
		      proxy_set_header X-Real-IP \$remote_addr;
		      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
		      proxy_set_header X-Forwarded-Proto "https";
		    }
		  }
		
		  server {
		    listen  *:80;
		    server_name  $DOMAIN;
		
		    client_max_body_size 1G;
		
		    return 301 https://$DOMAIN\$request_uri;
		  }
		}
	EOF
  echo "REPLACE_NGINX_CONFIG=true" | sudo tee --append /configurationProgress.sh
  echo "SSL_CONFIGURED=true" | sudo tee --append /configurationProgress.sh
}

# Convert hosted zone name into our valid domain (strip trailing '.' and prepend 'jenkins.')
function setDomain() {
  DOMAIN=$(sed -e 's/.$//' <<< $(echo jenkins.$HOSTED_ZONE_NAME))
}

ensureHostedZoneProvided "$@"
setDomain
downloadCertbot
getCertificates
replaceNginxConfiguration
