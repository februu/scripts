# febru's scripts

This repository contains bash scripts which I created. They are written and tested on my beloved Ubuntu. I run each of them through [ShellCheck](https://www.shellcheck.net/) before publishing it here so there shouldn't be any major fuckups in their logic _(hopefully)_. You can find specification of every script below.

> Also note that you are more than welcome to fork or create a pull request if you want to add something valuable to this repo. I'm still learning bash scripting so it's more than appreciated!

## motd.sh

This script displays a MOTD message with useful statistics and notifications about available updates, current tmux sessions and pending reboots. You can replace the ASCII art with your own (I used [this generator](https://patorjk.com/software/taag/)). Also feel free to add more notifications or modify the color palette.

To make this script work as intended, give it the ability to execute using `chmod +x motd.sh` and place it in `/etc/update-motd.d` directory (for Ubuntu).

![motd.sh screenshot](media/motd.png "This is how motd.sh looks on my vps")

## setup_nginx_certbot.sh

This script allows you to easily setup Nginx with SSL certificates using Certbot.

Prerequisites:

- Docker with Docker compose
- Domain (or domains) pointing to the server
- Root access or sudo privileges

Run the script and follow the steps. If there are any erros, check your domains again, remove the `nginx` folder using `sudo rm -rf nginx` and stop any running Nginx or Certbot containers. If you want to have full control over files created by Docker, feel free to chown the whole `nginx` directory after running the script.

### Usage

Type `sudo ./setup_nginx_certbot.sh <domain1> [domain2] [domain3] ...`. Example is show below.

```bash
sudo ./setup_nginx_certbot.sh domain1.com
```

### File structure

```
nginx
├── config
│   ├── conf.d
│   │   ├── domain1.com.conf            # Nginx configuration files per domain
│   │   └── ...
│   ├── nginx.conf                      # Main Nginx configuration file
│   └── ...
├── docker-compose.yml                  # You can use this file to compose up Nginx & Certbot manually
├── letsencrypt                         # Directory with certificate files
└── www                                 # Directory for your files
    └── domain1.com
        └── index.html
```
