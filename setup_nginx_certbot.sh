#!/bin/bash
# setup_nginx_certbot.sh - A script to set up Nginx and Certbot with SSL certificate generation
# Created by februu @github.com/februu

# More information about the script can be found at:
# https://github.com/februu/scripts 

# Color variables
RED='\033[0;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
RESET='\033[0m'

# Display important information
echo -e "\nBefore running this script, please ensure you have the following:"
echo -e "1. A domain (or domains) pointing to your server's IP address."
echo -e "2. Docker and Docker Compose installed on your server."
echo -e "3. Sudo privileges to run the script."
echo -e "\n${YELLOW}WARNING! This script won't work if you have a firewall blocking ports 80 and 443.${RESET}"
echo -e "${YELLOW}Please ensure that your firewall / cloud provider allows traffic on these ports.${RESET}"

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo -e "\n${RED}[ERROR] Please run this script as root.${RESET}"
    exit 1
fi

# Check if the user has provided a domain
if [ -z "${1}" ]; then
    echo -e "\n${RED}[ERROR] No domain provided. Usage: $0 <domain> [<domain2> ...]${RESET}"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "\n${RED}[ERROR] Docker is not installed. Please install Docker first.${RESET}"
    exit 1
fi

# Get user email for Let's Encrypt
EMAIL=""
while [[ -z "$EMAIL" ]]; do
    read -p "Enter your email address for Let's Encrypt certificate: " EMAIL
    if [[ ! "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo -e "${RED}[ERROR] Invalid email format. Please try again.${RESET}"
        EMAIL=""
    fi
done
echo -e "\n${GREEN}[INFO] Email address set to: ${EMAIL}${RESET}"
echo -e "${GREEN}[INFO] All prerequisites are met. Proceeding with the setup...${RESET}"

CURRENT_DIR=$(pwd)

# Create a directories for the Nginx and Certbot setup
mkdir -p $CURRENT_DIR/nginx/{config,letsencrypt,www}
mkdir -p $CURRENT_DIR/nginx/letsencrypt/{certs,www}

DOMAINS=""
MAIN_DOMAIN=$1
for domain in "$@"; do
    mkdir -p "${CURRENT_DIR}/nginx/www/${domain}"
    echo "<h1>Hello from ${domain}!</h1>" > "${CURRENT_DIR}/nginx/www/${domain}/index.html"
    DOMAINS="$DOMAINS -d $domain"
done

# Populate Nginx config files
echo -e "${GREEN}[INFO] Copying Nginx configuration files... ${RESET}"
docker run --rm -v "${CURRENT_DIR}/nginx/config:/tmp" nginx:stable-alpine sh -c "cp -r /etc/nginx/* /tmp"
rm -rf "${CURRENT_DIR}/nginx/config/modules"
mv "${CURRENT_DIR}/nginx/config/conf.d/default.conf" "${CURRENT_DIR}/nginx/config/conf.d/default.conf.disabled"
mkdir -p "${CURRENT_DIR}/nginx/config/snippets"
cat <<EOF > "${CURRENT_DIR}/nginx/config/snippets/acme.conf"
location ^~ /.well-known/acme-challenge/ {
    root /usr/share/nginx/letsencrypt;
    default_type "text/plain";
    try_files \$uri \$uri/ =404;
}
EOF
cat <<EOF > "${CURRENT_DIR}/nginx/config/conf.d/init.conf"
server {
    listen 80;
    server_name ${DOMAINS};

    include /etc/nginx/snippets/acme.conf;

    location / {
        return 404;
    }
}
EOF

# Create a Docker Compose file
echo -e "${GREEN}[INFO] Creating Docker Compose file... ${RESET}"
cat <<EOF > "${CURRENT_DIR}/nginx/docker-compose.yml"
services:
    nginx:
        image: nginx:stable-alpine
        container_name: nginx
        volumes:
            - ${CURRENT_DIR}/nginx/www:/usr/share/nginx/html:ro
            - ${CURRENT_DIR}/nginx/config:/etc/nginx:ro
            - ${CURRENT_DIR}/nginx/letsencrypt/certs:/etc/letsencrypt:ro
            - ${CURRENT_DIR}/nginx/letsencrypt/www:/usr/share/nginx/letsencrypt:ro
        ports:
            - 80:80
            - 443:443
        restart: always
    certbot:
        image: certbot/certbot:latest
        container_name: certbot
        volumes:
            - ${CURRENT_DIR}/nginx/letsencrypt/certs:/etc/letsencrypt
            - ${CURRENT_DIR}/nginx/letsencrypt/www:/usr/share/nginx/letsencrypt
        command: certonly --webroot -w /usr/share/nginx/letsencrypt --keep-until-expiring --email ${EMAIL} ${DOMAINS} --agree-tos
        depends_on:
            - nginx
EOF
echo -e "${GREEN}[INFO] Docker Compose file created successfully.${RESET}"

# Start Nginx and Certbot containers
echo -e "${GREEN}[INFO] Starting Nginx and Certbot containers...${RESET}"
docker compose -f "${CURRENT_DIR}/nginx/docker-compose.yml" down > /dev/null 2>&1
docker compose -f "${CURRENT_DIR}/nginx/docker-compose.yml" up -d nginx
sleep 5
echo -e "${GREEN}[INFO] Obtaining SSL certificates...${RESET}"
docker compose -f "${CURRENT_DIR}/nginx/docker-compose.yml" up certbot

if [ $? -ne 0 ]; then
    docker compose -f "${CURRENT_DIR}/nginx/docker-compose.yml" down
    echo "${RED}[ERROR]: Failed to generate certificates."   
    exit 1
fi 
docker compose -f "${CURRENT_DIR}/nginx/docker-compose.yml" down

# Remove the initial configuration and replace it with the final one
rm -f "${CURRENT_DIR}/nginx/config/conf.d/init.conf"
for domain in "$@"; do
cat <<EOF > "${CURRENT_DIR}/nginx/config/conf.d/${domain}.conf"
server {
    listen 80;
    server_name ${domain};

    include /etc/nginx/snippets/acme.conf;

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name ${domain};

    ssl_certificate     /etc/letsencrypt/live/${MAIN_DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${MAIN_DOMAIN}/privkey.pem;

    root /usr/share/nginx/html/${domain};
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF
done

# Start Nginx with the final configuration
docker compose -f "${CURRENT_DIR}/nginx/docker-compose.yml" up -d
echo -e "\n${GREEN}[INFO] Nginx and Certbot setup completed successfully!${RESET}"

# Display instructions for setting up a cron job
echo -e "\n${YELLOW}Remember to set up a cron job to renew the certificates automatically!${RESET}"
echo -e "${YELLOW}Make sure the crontab user has sufficient permission for Docker.${RESET}"
echo -e "${YELLOW} ou can add the following line to your crontab (crontab -e):${RESET}"
echo -e "${YELLOW}0 3 * * 1 /usr/bin/docker compose -f ${CURRENT_DIR}/nginx/docker-compose.yml up certbot ${RESET}"
echo -e "\n${GREEN}[INFO] Script successfully completed!${RESET}"