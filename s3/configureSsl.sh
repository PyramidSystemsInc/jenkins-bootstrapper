#! /bin/bash

# Ensure a hosted zone name is provided
if [ -z "$1" ]; then
  echo -e "${COLOR_RED}ERROR: Hosted zone name must be provided. Please re-run as follows:${COLOR_NONE}"
  echo -e "${COLOR_WHITE}    ./configureSsl.sh <HOSTED_ZONE_NAME>"
  echo -e "${COLOR_NONE}"
  exit 2
else
  HOSTED_ZONE_NAME=$1
fi

# Convert hosted zone name into our valid domain (strip trailing '.' and prepend 'jenkins.')
DOMAIN=$(sed -e 's/.$//' <<< $(echo jenkins.$HOSTED_ZONE_NAME))

# Download Certbot
cd /home/ec2-user
wget https://dl.eff.org/certbot-auto
chmod a+x certbot-auto

# Get certificates from Certbot (valid for 60 days)
sudo ./certbot-auto --nginx --debug -n --agree-tos --email jdiederiks@psi-it.com --domains $DOMAIN

# Replace NGINX config file
sudo rm /etc/nginx/nginx.conf
sudo mkdir -p /etc/nginx/
sudo touch /etc/nginx/nginx.conf
sudo ed -s /etc/nginx/nginx.conf >> /dev/null <<EOF
i
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /var/run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
  worker_connections 1024;
}

http {
  proxy_send_timeout 120;
  proxy_read_timeout 300;
  proxy_buffering    off;
  keepalive_timeout  5 5;
  tcp_nodelay        on;

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
.
w
q
EOF
